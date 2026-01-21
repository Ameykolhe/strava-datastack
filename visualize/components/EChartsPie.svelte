<script>
  import { onMount, onDestroy } from "svelte";
  import * as echarts from "echarts";

  export let data = [];
  export let x = "name";
  export let y = "value";
  export let title = "";
  export let labels = true;

  let chartEl;
  let chart;

  const buildSeriesData = () =>
    (data || []).map((row) => ({
      name: row?.[x],
      value: row?.[y],
    }));

  const getOption = () => {
    return {
      title: title ? { text: title, left: "center" } : undefined,
      tooltip: { trigger: "item" },
      series: [
        {
          type: "pie",
          radius: "60%",
          data: buildSeriesData(),
          label: { show: labels },
        },
      ],
    };
  };

  const render = () => {
    if (!chart) return;
    chart.setOption(getOption(), true);
  };

  onMount(() => {
    chart = echarts.init(chartEl);
    render();

    const handleResize = () => chart && chart.resize();
    window.addEventListener("resize", handleResize);

    return () => {
      window.removeEventListener("resize", handleResize);
      chart?.dispose();
      chart = null;
    };
  });

  onDestroy(() => {
    chart?.dispose();
    chart = null;
  });

  $: if (chart && data) {
    render();
  }
</script>

<div class="echart-pie" bind:this={chartEl} />

<style>
  .echart-pie {
    width: 100%;
    height: 360px;
  }
</style>
