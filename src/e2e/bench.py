import argparse
import json
import os
import shlex
import signal
import subprocess
import sys
import time
from pathlib import Path

import psutil


def _iter_process_tree(root_pid: int) -> list[psutil.Process]:
    try:
        root = psutil.Process(root_pid)
    except psutil.Error:
        return []
    processes = [root]
    try:
        processes.extend(root.children(recursive=True))
    except psutil.Error:
        pass
    return processes


def _sample_tree(processes: list[psutil.Process]) -> tuple[float, float, int]:
    total_user = 0.0
    total_system = 0.0
    total_rss = 0
    for proc in processes:
        try:
            cpu_times = proc.cpu_times()
            total_user += cpu_times.user
            total_system += cpu_times.system
            total_rss += proc.memory_info().rss
        except psutil.Error:
            continue
    return total_user, total_system, total_rss


def _measure_once(command: str, cwd: str | None = None) -> dict:
    start = time.perf_counter()
    process = subprocess.Popen(
        command,
        shell=True,
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        preexec_fn=os.setsid,
    )

    peak_rss = 0
    user_peak = 0.0
    system_peak = 0.0

    while process.poll() is None:
        procs = _iter_process_tree(process.pid)
        user_now, system_now, rss_now = _sample_tree(procs)
        if rss_now > peak_rss:
            peak_rss = rss_now
        if user_now > user_peak:
            user_peak = user_now
        if system_now > system_peak:
            system_peak = system_now
        time.sleep(0.01)

    stdout, stderr = process.communicate()
    end = time.perf_counter()
    procs = _iter_process_tree(process.pid)
    user_now, system_now, rss_now = _sample_tree(procs)
    peak_rss = max(peak_rss, rss_now)
    user_peak = max(user_peak, user_now)
    system_peak = max(system_peak, system_now)

    return {
        "exitCode": process.returncode,
        "stdout": stdout,
        "stderr": stderr,
        "wallMs": round((end - start) * 1000),
        "cpuMs": round((user_peak + system_peak) * 1000),
        "peakRssMb": round(peak_rss / (1024 * 1024)),
    }


def _median(values: list[int]) -> int:
    ordered = sorted(values)
    size = len(ordered)
    if size == 0:
        return 0
    mid = size // 2
    if size % 2 == 1:
        return ordered[mid]
    return round((ordered[mid - 1] + ordered[mid]) / 2)


def _run_benchmark(args: argparse.Namespace) -> int:
    warmup_runs = max(args.warmup_runs, 0)
    measure_runs = max(args.measure_runs, 1)
    warmups: list[dict] = []
    samples: list[dict] = []

    for _ in range(warmup_runs):
        result = _measure_once(args.command, cwd=args.cwd)
        warmups.append(result)
        if result["exitCode"] != 0:
            sys.stdout.write(json.dumps({
                "warmupRuns": warmup_runs,
                "measureRuns": measure_runs,
                "warmups": warmups,
                "samples": samples,
                "error": result,
            }))
            return result["exitCode"]

    for _ in range(measure_runs):
        result = _measure_once(args.command, cwd=args.cwd)
        samples.append(result)
        if result["exitCode"] != 0:
            sys.stdout.write(json.dumps({
                "warmupRuns": warmup_runs,
                "measureRuns": measure_runs,
                "warmups": warmups,
                "samples": samples,
                "error": result,
            }))
            return result["exitCode"]

    summary = {
        "warmupRuns": warmup_runs,
        "measureRuns": measure_runs,
        "wallMs": _median([sample["wallMs"] for sample in samples]),
        "cpuMs": _median([sample["cpuMs"] for sample in samples]),
        "peakRssMb": _median([sample["peakRssMb"] for sample in samples]),
        "samples": samples,
    }
    sys.stdout.write(json.dumps(summary))
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Benchmark a command with wall/cpu/rss metrics")
    parser.add_argument("--cwd", default=None, help="Working directory for the command")
    parser.add_argument("--warmup-runs", type=int, default=0)
    parser.add_argument("--measure-runs", type=int, default=1)
    parser.add_argument("command", help="Shell command to benchmark")
    args = parser.parse_args()
    return _run_benchmark(args)


if __name__ == "__main__":
    raise SystemExit(main())
