'use client';

import React from "react";
import { ApexOptions } from "apexcharts";
import dynamic from "next/dynamic";

const ReactApexChart = dynamic(() => import("react-apexcharts"), {
  ssr: false,
});

export default function LineChartOne() {
  const may2026Dates = Array.from({ length: 31 }, (_, i) => {
    const day = i + 1;
    return `May ${day}`;
  });

  const usageData = [
    142, 156, 189, 201, 178, 165, 143,
    198, 215, 234, 256, 289, 301, 278,
    245, 267, 289, 312, 334, 298, 276,
    254, 278, 301, 323, 345, 367, 389,
    401, 378, 356,
  ];

  const options: ApexOptions = {
    legend: {
      show: false,
      position: "top",
      horizontalAlign: "left",
    },
    colors: ["#465FFF"],
    chart: {
      fontFamily: "Outfit, sans-serif",
      height: 310,
      type: "area",
      toolbar: {
        show: false,
      },
      zoom: {
        enabled: false,
      },
    },
    stroke: {
      curve: "smooth",
      width: 2,
    },
    fill: {
      type: "gradient",
      gradient: {
        opacityFrom: 0.55,
        opacityTo: 0,
        shade: "#465FFF",
        gradientToColors: ["#465FFF"],
      },
    },
    markers: {
      size: 0,
      strokeColors: "#fff",
      strokeWidth: 2,
      hover: {
        size: 6,
      },
    },
    grid: {
      xaxis: {
        lines: {
          show: false,
        },
      },
      yaxis: {
        lines: {
          show: true,
        },
      },
      borderColor: "#E5E7EB",
      strokeDashArray: 4,
    },
    dataLabels: {
      enabled: false,
    },
    tooltip: {
      enabled: true,
      theme: "light",
      x: {
        formatter: (_value, opts) => {
          const index = opts?.dataPointIndex ?? 0;
          return `${may2026Dates[index]}, 2026`;
        },
      },
      y: {
        formatter: (value: number) => `${value} usages`,
      },
    },
    xaxis: {
      type: "category",
      categories: may2026Dates,
      axisBorder: {
        show: false,
      },
      axisTicks: {
        show: false,
      },
      tooltip: {
        enabled: false,
      },
      labels: {
        show: true,
        rotate: -45,
        rotateAlways: false,
        hideOverlappingLabels: true,
        showDuplicates: false,
        trim: true,
        style: {
          fontSize: "10px",
          fontFamily: "Outfit, sans-serif",
          fontWeight: 400,
          colors: ["#6B7280"],
        },
        formatter: (value) => {
          const label = String(value ?? "");
          const day = Number(label.replace("May ", ""));

          if (!Number.isFinite(day)) return "";

          return day % 5 === 0 ? label : "";
        },
      },
    },
    yaxis: {
      labels: {
        style: {
          fontSize: "11px",
          colors: ["#6B7280"],
          fontFamily: "Outfit, sans-serif",
        },
        formatter: (value: number) => {
          return value >= 1000
            ? `${(value / 1000).toFixed(1)}k`
            : value.toFixed(0);
        },
      },
      title: {
        text: "Usages",
        style: {
          fontSize: "11px",
          color: "#6B7280",
          fontFamily: "Outfit, sans-serif",
        },
      },
      min: 0,
    },
    plotOptions: {
      area: {
        fillTo: "origin",
      },
    },
  };

  const series = [
    {
      name: "Usage",
      data: usageData,
    },
  ];

  return (
    <div className="max-w-full overflow-x-auto custom-scrollbar">
      <div id="chartUsageOverTime" className="min-w-[1000px]">
        <ReactApexChart
          options={options}
          series={series}
          type="area"
          height={310}
        />
      </div>
    </div>
  );
}