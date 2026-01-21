<script>
  import { onMount, onDestroy } from "svelte";
  import * as echarts from "echarts";

  export let data = [];
  export let nameField = "zone_name";
  export let pctField = "pct_in_zone";
  export let minField = "zone_min_bpm";
  export let maxField = "zone_max_bpm";
  export let unit = "";
  export let height = 240;
  export let startColor = "#ADD8E6";
  export let endColor = "#00008B";

  let chartEl;
  let chart;
  let zones = [];
  let zoneColors = [];
  let resolvedData = [];
  let unsubscribe;
  let activeStore;

  const normalizeRows = (value) => {
    if (!value) return [];
    if (Array.isArray(value)) return Array.from(value);
    if (typeof value?.toArray === "function") return value.toArray();
    if (typeof value?.[Symbol.iterator] === "function") {
      return Array.from(value);
    }
    return [];
  };

  const toNumber = (value, fallback = 0) => {
    const numberValue = Number(value);
    return Number.isFinite(numberValue) ? numberValue : fallback;
  };

  const formatNumber = (value) => {
    if (value === null || value === undefined) return "N/A";
    const numberValue = Number(value);
    if (!Number.isFinite(numberValue)) return "N/A";
    return Math.round(numberValue).toString();
  };

  const hexToRgb = (hex) => {
    if (typeof hex !== "string") return null;
    const normalized = hex.trim().replace("#", "");
    if (![3, 6].includes(normalized.length)) return null;
    const full = normalized.length === 3
      ? normalized.split("").map((c) => c + c).join("")
      : normalized;
    const intValue = parseInt(full, 16);
    return {
      r: (intValue >> 16) & 255,
      g: (intValue >> 8) & 255,
      b: intValue & 255
    };
  };

  const interpolateColor = (start, end, t) => {
    const startRgb = hexToRgb(start);
    const endRgb = hexToRgb(end);
    if (!startRgb || !endRgb) return end || start || "#94a3b8";
    const mix = (a, b) => Math.round(a + (b - a) * t);
    const r = mix(startRgb.r, endRgb.r);
    const g = mix(startRgb.g, endRgb.g);
    const b = mix(startRgb.b, endRgb.b);
    return `rgb(${r}, ${g}, ${b})`;
  };

  const buildGradient = (start, end, steps) => {
    if (steps <= 1) return [end || start || "#94a3b8"];
    const colors = [];
    for (let i = 0; i < steps; i += 1) {
      colors.push(interpolateColor(start, end, i / (steps - 1)));
    }
    return colors;
  };

  const getZones = () => {
    if (!Array.isArray(resolvedData)) return [];
    const zones = resolvedData
      .map((row) => ({
        zoneId: row?.zone_id,
        name: row?.[nameField],
        pct: toNumber(row?.[pctField]),
        min: row?.[minField],
        max: row?.[maxField]
      }))
      .filter((row) => row.name !== null && row.name !== undefined);
    zones.sort((a, b) => {
      if (a.zoneId === undefined || b.zoneId === undefined) return 0;
      return a.zoneId - b.zoneId;
    });
    return zones;
  };

  const getZoneColors = (zoneCount) => {
    return buildGradient(startColor, endColor, zoneCount);
  };

  const buildOption = (zones, colors) => {
    const labels = zones.map((zone) => zone.name);
    const seriesData = zones.map((zone, index) => ({
      value: zone.pct,
      itemStyle: { color: colors[index] }
    }));

    return {
      grid: { left: 10, right: 10, top: 10, bottom: 32, containLabel: true },
      xAxis: {
        type: "category",
        data: labels,
        axisTick: { alignWithLabel: true },
        axisLabel: { interval: 0 }
      },
      yAxis: {
        type: "value",
        min: 0,
        max: 100,
        axisLabel: { formatter: "{value}%" }
      },
      tooltip: {
        trigger: "item",
        formatter: (params) => {
          const zone = zones[params.dataIndex];
          if (!zone) return "";
          const minText = formatNumber(zone.min);
          const maxText = formatNumber(zone.max);
          const unitLabel = unit ? ` ${unit}` : "";
          return `
            <div style='font-weight: 600;'>${zone.name}</div>
            <div>${toNumber(zone.pct).toFixed(1)}%</div>
            <div>Min: ${minText}${unitLabel}</div>
            <div>Max: ${maxText}${unitLabel}</div>
          `;
        }
      },
      series: [
        {
          type: "bar",
          data: seriesData,
          barMaxWidth: 40
        }
      ]
    };
  };

  const render = () => {
    if (!chart) return;
    if (zones.length === 0) {
      chart.clear();
      return;
    }
    chart.setOption(buildOption(zones, zoneColors), true);
  };

  onMount(() => {
    if (!chartEl) return;
    chart = echarts.init(chartEl);
    render();
    setTimeout(() => {
      chart?.resize();
    }, 0);

    const handleResize = () => chart && chart.resize();
    window.addEventListener("resize", handleResize);

    return () => {
      window.removeEventListener("resize", handleResize);
      chart?.dispose();
      chart = null;
    };
  });

  onDestroy(() => {
    if (unsubscribe) {
      unsubscribe();
      unsubscribe = null;
    }
    chart?.dispose();
    chart = null;
  });

  const updateResolvedData = (value) => {
    resolvedData = normalizeRows(value);
  };

  $: if (data !== activeStore) {
    if (unsubscribe) {
      unsubscribe();
      unsubscribe = null;
    }

    activeStore = data;

    if (data && typeof data.subscribe === "function") {
      unsubscribe = data.subscribe((value) => {
        updateResolvedData(value);
      });
      if (typeof data.fetch === "function") {
        data.fetch();
      }
    } else {
      updateResolvedData(data);
    }
  }

  $: zones = getZones();
  $: zoneColors = getZoneColors(zones.length);

  $: if (chart) {
    zones;
    zoneColors;
    render();
  }
</script>

<div class="zone-distribution">
  <div class="chart" style="height: {height}px;" bind:this={chartEl}></div>
  {#if zones.length === 0}
    <div class="empty">No zone data available.</div>
  {/if}
  <div class="legend">
    {#each zones as zone, index}
      <div class="legend-row">
        <span
          class="swatch"
          style="background-color: {zoneColors[index]};"
        />
        <span class="name">{zone.name}</span>
        <span class="range">
          {formatNumber(zone.min)} - {formatNumber(zone.max)}{unit ? ` ${unit}` : ""}
        </span>
      </div>
    {/each}
  </div>
</div>

<style>
  .zone-distribution {
    display: grid;
    gap: 12px;
  }

  .chart {
    width: 100%;
  }

  .legend {
    display: grid;
    gap: 6px;
  }

  .empty {
    font-size: 13px;
    color: rgba(0, 0, 0, 0.6);
  }

  .legend-row {
    display: grid;
    grid-template-columns: 14px minmax(80px, 1fr) auto;
    align-items: center;
    gap: 8px;
    font-size: 13px;
  }

  .swatch {
    width: 12px;
    height: 12px;
    border-radius: 3px;
    border: 1px solid rgba(0, 0, 0, 0.08);
  }

  .range {
    color: rgba(0, 0, 0, 0.65);
    font-variant-numeric: tabular-nums;
  }
</style>
