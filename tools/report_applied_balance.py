"""Summarize consecutive campaigns separately from independent stage probes."""
import csv
import json
import math
import statistics
import sys
from collections import Counter, defaultdict
from pathlib import Path


def summarize(paths):
    campaigns, probes = defaultdict(list), defaultdict(list)
    fights = 0
    for path in paths:
        with Path(path).open(encoding="utf-8") as source:
            for row in csv.DictReader(source):
                fights += 1
                key = row["profile"], row["policy"]
                (campaigns if row["mode"] == "campaign" else probes)[key].append(row)
    result = {"sources": paths, "fights": fights, "campaigns": [], "probes": []}
    for (profile, policy), rows in sorted(campaigns.items()):
        seeds = {r["seed"] for r in rows}
        cleared = {seed: max([0] + [int(r["stage"]) for r in rows if r["seed"] == seed
                                   and r["won"] == "1" and r["encounter"] == "3"]) for seed in seeds}
        thresholds = {str(stage): sum(last >= stage for last in cleared.values())
                      for stage in (1, 5, 10, 20, 40, 60, 80, 100, 120)}
        n, k, z = len(seeds), thresholds["20"], 1.96
        center = (k/n + z*z/(2*n))/(1 + z*z/n)
        margin = z*math.sqrt(k/n*(1-k/n)/n + z*z/(4*n*n))/(1 + z*z/n)
        result["campaigns"].append({"profile": profile, "policy": policy, "runs": n,
            "cleared": thresholds, "mean_stages": round(statistics.mean(cleared.values()), 2),
            "mean_region1_stages": round(statistics.mean(min(20, value) for value in cleared.values()), 2),
            "max_stages": max(cleared.values()), "region1_percent": round(k/n*100, 1),
            "region1_wilson95": [max(0, round((center-margin)*100, 1)), min(100, round((center+margin)*100, 1))],
            "failures": dict(Counter(f'{r["stage"]}:{r["boss"]}' for r in rows if r["won"] == "0")),
            "timeouts": sum(int(r["timeout"]) for r in rows)})
    regions = ["human", "hearts", "diamonds", "clubs", "spades", "unknown"]
    for (profile, policy), rows in sorted(probes.items()):
        for index, region in enumerate(regions):
            group = [r for r in rows if index*20 < int(r["stage"]) <= (index+1)*20]
            if group:
                result["probes"].append({"profile": profile, "policy": policy, "region": region,
                    "fights": len(group), "positions": len({(r["stage"], r["encounter"]) for r in group}),
                    "win_percent": round(100*statistics.mean(int(r["won"]) for r in group), 1),
                    "timeouts": sum(int(r["timeout"]) for r in group)})
    return result


if __name__ == "__main__":
    result = summarize(sys.argv[2:])
    Path(sys.argv[1]).write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(result, ensure_ascii=False, indent=2))
