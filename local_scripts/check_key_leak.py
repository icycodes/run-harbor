from __future__ import annotations

import argparse
import math
import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path


MASK = "(*****SECRET_LEAK_DETECTED*****)"
SECRET_NAME_RE = re.compile(
	r"(?:SECRET|TOKEN|KEY|PASSWORD|PASSWD|PRIVATE|CREDENTIAL|AUTH|SESSION|COOKIE)",
	re.IGNORECASE,
)
PLACEHOLDER_VALUE_RE = re.compile(
	r"^(?:changeme|example|your[_-].*|placeholder|dummy|test|sample)$",
	re.IGNORECASE,
)
DEFAULT_EXCLUDED_DIRS = {
	".git",
	"node_modules",
	"__pycache__",
	".pytest_cache",
}


@dataclass(frozen=True)
class Secret:
	name: str
	value: str
	source: str


@dataclass(frozen=True)
class LeakOccurrence:
	secret_name: str
	line: int
	column: int
	matched_text: str
	match_length: int


@dataclass(frozen=True)
class FileResult:
	path: Path
	replacements: int
	occurrences: list[LeakOccurrence]


def build_parser() -> argparse.ArgumentParser:
	repo_root = Path(__file__).resolve().parent.parent
	parser = argparse.ArgumentParser(
		description="Scan the jobs directory for leaked secrets and mask them in place.",
	)
	parser.add_argument(
		"--env-file",
		type=Path,
		default=repo_root / ".env",
		help="Path to the .env file to load secrets from.",
	)
	parser.add_argument(
		"--jobs-dir",
		type=Path,
		default=repo_root / "jobs",
		help="Path to the jobs directory to scan.",
	)
	parser.add_argument(
		"--mask",
		default=MASK,
		help="Mask text used to replace leaked secret values.",
	)
	parser.add_argument(
		"--dry-run",
		action="store_true",
		help="Report leaks without modifying files.",
	)
	parser.add_argument(
		"--include-env",
		action="store_true",
		help="Also scan secret-like variables from the current process environment.",
	)
	parser.add_argument(
		"--min-secret-length",
		type=int,
		default=8,
		help="Minimum secret length to consider.",
	)
	parser.add_argument(
		"--prefix-fraction",
		type=float,
		default=1 / 3,
		help="Minimum fraction of a secret that must appear before it is treated as a leak.",
	)
	parser.add_argument(
		"--min-prefix-length",
		type=int,
		default=8,
		help="Absolute minimum prefix length required for partial secret matching.",
	)
	return parser


def load_env_file(env_file: Path) -> dict[str, str]:
	env_vars: dict[str, str] = {}
	if not env_file.exists():
		return env_vars

	for raw_line in env_file.read_text(encoding="utf-8").splitlines():
		line = raw_line.strip()
		if not line or line.startswith("#"):
			continue

		if line.startswith("export "):
			line = line[len("export ") :].strip()

		if "=" not in line:
			continue

		key, value = line.split("=", 1)
		key = key.strip()
		value = value.strip()

		if not key:
			continue

		if value and value[0] == value[-1] and value[0] in {'"', "'"}:
			value = value[1:-1]

		env_vars[key] = value

	return env_vars


def is_secret_name(name: str) -> bool:
	if not SECRET_NAME_RE.search(name):
		return False
	return name.upper() not in {"GPG_KEY", "SSH_AUTH_SOCK"}


def is_viable_secret(value: str, min_secret_length: int) -> bool:
	stripped = value.strip()
	if len(stripped) < min_secret_length:
		return False
	if stripped.lower() in {"true", "false", "null", "none"}:
		return False
	if "\n" in stripped or "\r" in stripped:
		return False
	if PLACEHOLDER_VALUE_RE.match(stripped):
		return False
	return True


def collect_secrets(
	env_file_values: dict[str, str],
	include_environment: bool,
	min_secret_length: int,
) -> list[Secret]:
	secrets: dict[str, Secret] = {}

	for name, value in env_file_values.items():
		if is_secret_name(name) and is_viable_secret(value, min_secret_length):
			secrets[value] = Secret(name=name, value=value, source="env-file")

	if include_environment:
		for name, value in os.environ.items():
			if value in secrets:
				continue
			if is_secret_name(name) and is_viable_secret(value, min_secret_length):
				secrets[value] = Secret(name=name, value=value, source="process-env")

	return sorted(secrets.values(), key=lambda secret: len(secret.value), reverse=True)


def should_skip_path(path: Path) -> bool:
	return any(part in DEFAULT_EXCLUDED_DIRS for part in path.parts)


def is_likely_binary(data: bytes) -> bool:
	if not data:
		return False
	if b"\x00" in data:
		return True
	sample = data[:1024]
	text_bytes = sum(
		byte in b"\t\n\r\f\b" or 32 <= byte <= 126 for byte in sample
	)
	return text_bytes / len(sample) < 0.85


def find_line_and_column(text: str, offset: int) -> tuple[int, int]:
	line = text.count("\n", 0, offset) + 1
	last_newline = text.rfind("\n", 0, offset)
	if last_newline == -1:
		column = offset + 1
	else:
		column = offset - last_newline
	return line, column


def get_min_prefix_length(secret: Secret, prefix_fraction: float, min_prefix_length: int) -> int:
	required = math.ceil(len(secret.value) * prefix_fraction)
	return min(len(secret.value), max(min_prefix_length, required))


def collect_occurrences(
	text: str,
	secrets: list[Secret],
	prefix_fraction: float,
	min_prefix_length: int,
) -> tuple[list[LeakOccurrence], list[tuple[int, int]]]:
	occurrences: list[LeakOccurrence] = []
	occupied_ranges: list[tuple[int, int]] = []

	for secret in secrets:
		prefix_length = get_min_prefix_length(secret, prefix_fraction, min_prefix_length)
		needle = secret.value[:prefix_length]
		start = 0
		while True:
			index = text.find(needle, start)
			if index == -1:
				break

			end = index + prefix_length
			while end < len(text) and end - index < len(secret.value):
				if text[end] != secret.value[end - index]:
					break
				end += 1

			overlaps = any(index < existing_end and end > existing_start for existing_start, existing_end in occupied_ranges)
			if not overlaps:
				line, column = find_line_and_column(text, index)
				matched_text = text[index:end]
				occurrences.append(
					LeakOccurrence(
						secret_name=secret.name,
						line=line,
						column=column,
						matched_text=matched_text,
						match_length=len(matched_text),
					)
				)
				occupied_ranges.append((index, end))

			start = index + 1

	occurrences.sort(key=lambda item: (item.line, item.column, item.secret_name, -item.match_length))
	occupied_ranges.sort()
	return occurrences, occupied_ranges


def mask_file(
	path: Path,
	secrets: list[Secret],
	mask: str,
	dry_run: bool,
	prefix_fraction: float,
	min_prefix_length: int,
) -> FileResult | None:
	try:
		content = path.read_bytes()
	except OSError as exc:
		print(f"[warn] failed to read {path}: {exc}", file=sys.stderr)
		return None

	if is_likely_binary(content):
		return None

	text = content.decode("utf-8", errors="surrogateescape")
	occurrences, ranges = collect_occurrences(
		text,
		secrets,
		prefix_fraction=prefix_fraction,
		min_prefix_length=min_prefix_length,
	)
	replacements = len(ranges)

	if replacements == 0:
		return None

	if not dry_run:
		try:
			parts: list[str] = []
			last_index = 0
			for start, end in ranges:
				parts.append(text[last_index:start])
				parts.append(mask)
				last_index = end
			parts.append(text[last_index:])
			masked_text = "".join(parts)
			path.write_bytes(masked_text.encode("utf-8", errors="surrogateescape"))
		except OSError as exc:
			print(f"[warn] failed to write {path}: {exc}", file=sys.stderr)
			return None

	return FileResult(path=path, replacements=replacements, occurrences=occurrences)


def scan_jobs(
	jobs_dir: Path,
	secrets: list[Secret],
	mask: str,
	dry_run: bool,
	prefix_fraction: float,
	min_prefix_length: int,
) -> list[FileResult]:
	results: list[FileResult] = []
	for path in jobs_dir.rglob("*"):
		if not path.is_file() or should_skip_path(path):
			continue
		result = mask_file(
			path,
			secrets,
			mask=mask,
			dry_run=dry_run,
			prefix_fraction=prefix_fraction,
			min_prefix_length=min_prefix_length,
		)
		if result is not None:
			results.append(result)
	return results


def main() -> int:
	parser = build_parser()
	args = parser.parse_args()

	env_file = args.env_file.resolve()
	jobs_dir = args.jobs_dir.resolve()
	env_values = load_env_file(env_file)
	secrets = collect_secrets(
		env_values,
		include_environment=args.include_env,
		min_secret_length=args.min_secret_length,
	)

	if not jobs_dir.exists():
		parser.error(f"jobs directory does not exist: {jobs_dir}")

	if not secrets:
		source_hint = str(env_file) if env_file.exists() else f"missing env file: {env_file}"
		print(f"No secret values found to scan. Source: {source_hint}")
		return 0

	results = scan_jobs(
		jobs_dir,
		secrets=secrets,
		mask=args.mask,
		dry_run=args.dry_run,
		prefix_fraction=args.prefix_fraction,
		min_prefix_length=args.min_prefix_length,
	)

	action = "would mask" if args.dry_run else "masked"
	print(
		f"Scanned {jobs_dir} using {len(secrets)} secret value(s); {action} leaks in {len(results)} file(s)."
	)
	for result in results:
		print(f"- {result.path}: {result.replacements} replacement(s)")
		for occurrence in result.occurrences:
			print(
				"  "
				f"{result.path}:{occurrence.line}:{occurrence.column}"
				f" {occurrence.secret_name}"
			)

	return 1 if results else 0


if __name__ == "__main__":
	raise SystemExit(main())
