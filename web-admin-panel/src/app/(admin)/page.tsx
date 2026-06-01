// src/app/admin/dashboard/page.tsx
'use client';

import React, { useEffect, useState } from "react";
import ComponentCard from "@/components/common/ComponentCard";
import PageBreadCrumb from "@/components/common/PageBreadCrumb";
import LineChartOne from "@/components/charts/line/LineChartOne";

// Dummy user data (original)
const dummyUsers = [
  {
    id: 1,
    name: "Ahmad Rizki",
    email: "ahmad.rizki@email.com",
    age: 12,
    assessmentDate: "2024-01-15",
    dyslexiaLevel: "Mild",
    status: "Active",
  },
  {
    id: 2,
    name: "Siti Nurhaliza",
    email: "siti.nur@email.com",
    age: 10,
    assessmentDate: "2024-02-20",
    dyslexiaLevel: "Moderate",
    status: "Active",
  },
  {
    id: 3,
    name: "Budi Santoso",
    email: "budi.santoso@email.com",
    age: 14,
    assessmentDate: "2024-03-10",
    dyslexiaLevel: "Severe",
    status: "Pending",
  },
  {
    id: 4,
    name: "Dewi Lestari",
    email: "dewi.lestari@email.com",
    age: 11,
    assessmentDate: "2024-03-25",
    dyslexiaLevel: "Mild",
    status: "Active",
  },
  {
    id: 5,
    name: "Eko Prasetyo",
    email: "eko.prasetyo@email.com",
    age: 13,
    assessmentDate: "2024-04-05",
    dyslexiaLevel: "Moderate",
    status: "Inactive",
  },
];

// Dummy data for User Activity
const userActivityData = [
  { user: "user_001", action: "Read Text", time: "10:32" },
  { user: "user_002", action: "Summarize", time: "10:12" },
  { user: "user_003", action: "Screening", time: "09:58" },
  { user: "user_004", action: "Define", time: "09:41" },
  { user: "user_005", action: "Personalize", time: "09:15" },
];

// Dummy data for Access Codes
const accessCodesData = [
  { code: "ABCD-1234", status: "Active", users: 25 },
  { code: "EFGH-5678", status: "Active", users: 18 },
  { code: "IJKL-9012", status: "Expired", users: 0 },
  { code: "MNOP-3456", status: "Active", users: 11 },
];

// Dummy data for Feature History
const featureHistoryData = [
  { feature: "Reader Tools", usageCount: 3482, trend: "up" },
  { feature: "Summarize", usageCount: 1026, trend: "up" },
  { feature: "Define", usageCount: 1214, trend: "up" },
  { feature: "Personalize", usageCount: 872, trend: "up" },
  { feature: "Screening", usageCount: 812, trend: "up" },
];

// ✅ Updated Summary stats for Dashboard Overview
const summaryStats = {
  totalUsers: 1248,
  activeToday: 243,
  screeningsCompleted: 812,
  textsProcessed: 5671,
};

export default function DyslexiaDashboard() {
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    document.title = "Dyslexia User Management - QUB Admin";
  }, []);

  const handleViewDetail = (userId: number) => {
    alert(`Viewing details for user ID: ${userId}`);
  };

  const getLevelColor = (level: string) => {
    switch (level) {
      case "Mild":
        return "bg-green-100 text-green-800";
      case "Moderate":
        return "bg-yellow-100 text-yellow-800";
      case "Severe":
        return "bg-red-100 text-red-800";
      default:
        return "bg-gray-100 text-gray-800";
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case "Active":
        return "bg-blue-100 text-blue-800";
      case "Pending":
        return "bg-orange-100 text-orange-800";
      case "Expired":
        return "bg-red-100 text-red-800";
      case "Inactive":
        return "bg-gray-100 text-gray-800";
      default:
        return "bg-gray-100 text-gray-800";
    }
  };

  const getTrendIcon = (trend: string) => {
    return trend === "up" ? (
      <svg className="w-4 h-4 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 10l7-7m0 0l7 7m-7-7v18" />
      </svg>
    ) : (
      <svg className="w-4 h-4 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 14l-7 7m0 0l-7-7m7 7V3" />
      </svg>
    );
  };

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      {/* Breadcrumb */}
      <PageBreadCrumb pageTitle="Dashboard" />

      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Dyslexia User Management</h1>
        <p className="text-gray-600 mt-1">Manage and monitor users with dyslexia assessments</p>
      </div>

      {/* ✅ Dashboard Overview - 4 Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        {/* Total Users */}
        <ComponentCard title="Total Users" className="text-center">
          <div className="flex items-center justify-center mb-2">
            <svg className="w-8 h-8 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
            </svg>
          </div>
          <p className="text-3xl font-bold text-gray-900">{summaryStats.totalUsers.toLocaleString()}</p>
        </ComponentCard>

        {/* Active Today */}
        <ComponentCard title="Active Today" className="text-center">
          <div className="flex items-center justify-center mb-2">
            <svg className="w-8 h-8 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <p className="text-3xl font-bold text-green-600">{summaryStats.activeToday.toLocaleString()}</p>
        </ComponentCard>

        {/* Screenings Completed */}
        <ComponentCard title="Screenings Completed" className="text-center">
          <div className="flex items-center justify-center mb-2">
            <svg className="w-8 h-8 text-orange-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
            </svg>
          </div>
          <p className="text-3xl font-bold text-orange-600">{summaryStats.screeningsCompleted.toLocaleString()}</p>
        </ComponentCard>

        {/* Texts Processed */}
        <ComponentCard title="Texts Processed" className="text-center">
          <div className="flex items-center justify-center mb-2">
            <svg className="w-8 h-8 text-purple-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
          </div>
          <p className="text-3xl font-bold text-purple-600">{summaryStats.textsProcessed.toLocaleString()}</p>
        </ComponentCard>
      </div>

      {/* Usage Over Time Chart */}
      <ComponentCard title="Usage Over Time" className="mb-6">
        <div className="h-[350px]">
          {mounted && <LineChartOne />}
        </div>
      </ComponentCard>

      {/* User Activity & Access Codes */}
      <div className="grid grid-cols-1 xl:grid-cols-2 gap-6 mb-6">
        {/* User Activity */}
        <ComponentCard title="User Activity (Recent)">
          <div className="overflow-x-auto max-h-[280px] overflow-y-auto">
            <table className="w-full">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">User</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Action</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Time</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {userActivityData.map((activity, index) => (
                  <tr key={index} className="hover:bg-gray-50">
                    <td className="px-6 py-3 text-sm text-gray-900">{activity.user}</td>
                    <td className="px-6 py-3 text-sm text-gray-700">{activity.action}</td>
                    <td className="px-6 py-3 text-sm text-gray-700">{activity.time}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </ComponentCard>

        {/* Access Codes */}
        <ComponentCard title="Access Codes">
          <div className="overflow-x-auto max-h-[280px] overflow-y-auto">
            <table className="w-full">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Code</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Users</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {accessCodesData.map((code, index) => (
                  <tr key={index} className="hover:bg-gray-50">
                    <td className="px-6 py-3 text-sm font-mono text-gray-900">{code.code}</td>
                    <td className="px-6 py-3">
                      <span className={`px-2 py-1 text-xs font-medium rounded-full ${getStatusColor(code.status)}`}>
                        {code.status}
                      </span>
                    </td>
                    <td className="px-6 py-3 text-sm text-gray-700">{code.users}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </ComponentCard>
      </div>

      {/* Feature History */}
      <ComponentCard title="Feature History" className="mb-6">
        <div className="overflow-x-auto max-h-[300px] overflow-y-auto">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Feature</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Usage Count</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Trend</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {featureHistoryData.map((feature, index) => (
                <tr key={index} className="hover:bg-gray-50">
                  <td className="px-6 py-3 text-sm font-medium text-gray-900">{feature.feature}</td>
                  <td className="px-6 py-3 text-sm text-gray-700">{feature.usageCount.toLocaleString()}</td>
                  <td className="px-6 py-3 flex items-center gap-2">
                    {getTrendIcon(feature.trend)}
                    <span className="text-sm text-green-600">{feature.trend === "up" ? "+12%" : "-5%"}</span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </ComponentCard>

      {/* User List Table (Original) */}
      <ComponentCard title="User List">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Email</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Age</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Assessment Date</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Dyslexia Level</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Action</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {dummyUsers.map((user) => (
                <tr key={user.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm font-medium text-gray-900">{user.name}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-500">{user.email}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-900">{user.age}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-500">{user.assessmentDate}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`px-2 py-1 text-xs font-medium rounded-full ${getLevelColor(user.dyslexiaLevel)}`}>
                      {user.dyslexiaLevel}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`px-2 py-1 text-xs font-medium rounded-full ${getStatusColor(user.status)}`}>
                      {user.status}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <button
                      onClick={() => handleViewDetail(user.id)}
                      className="px-3 py-1 text-sm font-medium text-white bg-blue-600 rounded hover:bg-blue-700 transition-colors"
                    >
                      View Detail
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </ComponentCard>
    </div>
  );
}