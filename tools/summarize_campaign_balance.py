"""Summarize the controlled LÖVE combat simulation; no third-party packages."""
import csv
import json
import math
import statistics
import sys
from collections import Counter
from pathlib import Path


def summarize(path):
    rows = list(csv.DictReader(Path(path).open(encoding="utf-8")))
    summary = list(csv.DictReader(Path(path).with_name(Path(path).stem + "_summary.csv").open()))
    result = {"source": str(path), "encounters": len(rows), "campaigns": [], "probes": [], "bosses": []}
    for entry in summary:
        n, k = int(entry["seeds"]), int(entry["completed"])
        z = 1.96
        center = (k / n + z * z / (2 * n)) / (1 + z * z / n)
        margin = z * math.sqrt(k / n * (1 - k / n) / n + z * z / (4 * n * n)) / (1 + z * z / n)
        campaign = {**entry, "win_percent": round(100 * k / n, 1),
                    "wilson95": [max(0, round(100 * (center - margin), 1)), min(100, round(100 * (center + margin), 1))]}
        result["campaigns"].append(campaign)
        base = [r for r in rows if r["profile"] == entry["profile"] and r["policy"] == entry["policy"]]
        campaign["failures"] = dict(Counter("stage " + r["stage"] + " boss " + r["boss"]
                                              for r in base if r["mode"] == "campaign" and r["won"] == "0"))
        probes = [r for r in base if r["mode"] == "probe"]
        for stage in range(1, 21):
            data = [r for r in probes if int(r["stage"]) == stage]
            result["probes"].append({"profile": entry["profile"], "policy": entry["policy"], "stage": stage,
                "win_percent": round(100 * statistics.mean(int(r["won"]) for r in data), 1),
                "turns": round(statistics.mean(int(r["turns"]) for r in data), 2),
                "aura": round(statistics.mean(int(r["aura_mean"]) for r in data)),
                "timeouts": sum(int(r["timeout"]) for r in data),
                "oneshot_per_landed_hit": round(100 * sum(int(r["kill_hits"]) for r in data) /
                                                max(1, sum(int(r["hits"]) for r in data)), 1)})
        for boss in range(1, 11):
            data = [r for r in probes if int(r["boss"]) == boss]
            if data:
                result["bosses"].append({"profile": entry["profile"], "policy": entry["policy"], "boss": boss,
                    "n": len(data), "win_percent": round(100 * statistics.mean(int(r["won"]) for r in data), 1),
                    "turns": round(statistics.mean(int(r["turns"]) for r in data), 2)})
    return result


if __name__ == "__main__":
    for filename in sys.argv[1:]:
        result = summarize(filename)
        Path(filename).with_suffix(".json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
        print(filename, result["encounters"], "encounters")
        for row in result["campaigns"]:
            print(row["profile"], row["policy"], str(row["win_percent"]) + "%", "95%", row["wilson95"],
                  "mean stages", round(float(row["mean_stages"]), 2))
        print("Normal/tactical boss probes:", [(r["boss"], r["win_percent"], r["n"]) for r in result["bosses"]
                                              if r["profile"] == "normal" and r["policy"] == "tactical"])
