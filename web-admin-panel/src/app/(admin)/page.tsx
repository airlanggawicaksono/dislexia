// src/app/(admin)/page.tsx
'use client';

import React, { useEffect, useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import ComponentCard from "@/components/common/ComponentCard";
import PageBreadCrumb from "@/components/common/PageBreadCrumb";
import LineChartOne from "@/components/charts/line/LineChartOne";

// Type definitions
interface User {
  user_id: string;
  display_name: string;
  account_md5: string;
  is_active: boolean;
  created_at: string;
  last_login: string | null;
}

interface HistoryItem {
  id: string;
  session_id: string;
  user_id: string;
  feature: "summarize" | "professionalize" | "define" | "screen";
  input_text: string;
  output_text: string | null;
  created_at: string;
}

interface DashboardStats {
  totalUsers: number;
  activeToday: number;
  screeningsCompleted: number;
  textsProcessed: number;
}

interface UserActivity {
  user: string;
  action: string;
  time: string;
  feature: string;
}

interface FeatureUsage {
  feature: string;
  usageCount: number;
  trend: "up" | "down";
  trendPercent: number;
}

export default function DyslexiaDashboard() {
  const router = useRouter();
  const [mounted, setMounted] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  
  const [stats, setStats] = useState<DashboardStats>({
    totalUsers: 0,
    activeToday: 0,
    screeningsCompleted: 0,
    textsProcessed: 0,
  });
  const [recentActivity, setRecentActivity] = useState<UserActivity[]>([]);
  const [featureUsage, setFeatureUsage] = useState<FeatureUsage[]>([]);
  const [users, setUsers] = useState<User[]>([]);

  const fetchDashboardData = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      
      const token = localStorage.getItem("admin_token");
      if (!token) {
        router.push("/signin");
        return;
      }

      const [usersResponse, historyResponse] = await Promise.all([
        fetch(`/api/proxy/api/v1/admin/users`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
        fetch(`/api/proxy/api/v1/admin/history`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
      ]);

      if (usersResponse.status === 401 || historyResponse.status === 401) {
        localStorage.removeItem("admin_token");
        localStorage.removeItem("admin_info");
        document.cookie = "admin_token=; path=/; max-age=0";
        router.push("/signin");
        return;
      }

      if (!usersResponse.ok || !historyResponse.ok) {
        throw new Error("Failed to fetch dashboard data");
      }

      const usersData = await usersResponse.json();
      const historyData = await historyResponse.json();

      const usersList: User[] = usersData.items || [];
      const historyList: HistoryItem[] = historyData.items || [];

      setUsers(usersList);

      const today = new Date();
      today.setHours(0, 0, 0, 0);
      
      const activeToday = usersList.filter((user) => {
        if (!user.last_login) return false;
        const lastLogin = new Date(user.last_login);
        return lastLogin >= today;
      }).length;

      const screeningsCompleted = historyList.filter(
        (item) => item.feature === "screen"
      ).length;

      const textsProcessed = historyList.filter(
        (item) =>
          item.feature === "summarize" || item.feature === "professionalize"
      ).length;

      setStats({
        totalUsers: usersData.total || usersList.length,
        activeToday,
        screeningsCompleted,
        textsProcessed,
      });

      const activity: UserActivity[] = historyList
        .slice(0, 10)
        .map((item) => {
          const user = usersList.find((u) => u.user_id === item.user_id);
          const time = new Date(item.created_at);
          return {
            user: user?.display_name || "Unknown User",
            action: formatFeatureName(item.feature),
            time: time.toLocaleTimeString("en-US", {
              hour: "2-digit",
              minute: "2-digit",
            }),
            feature: item.feature,
          };
        });
      setRecentActivity(activity);

      const featureCounts: Record<string, number> = {
        summarize: 0,
        professionalize: 0,
        define: 0,
        screen: 0,
      };
      
      historyList.forEach((item) => {
        if (featureCounts.hasOwnProperty(item.feature)) {
          featureCounts[item.feature]++;
        }
      });

      const features: FeatureUsage[] = Object.entries(featureCounts).map(
        ([feature, count]) => ({
          feature: formatFeatureName(feature),
          usageCount: count,
          trend: "up",
          trendPercent: 12,
        })
      );
      
      features.sort((a, b) => b.usageCount - a.usageCount);
      setFeatureUsage(features);
    } catch (err: any) {
      console.error("Error fetching dashboard data:", err);
      setError(err.message || "Failed to load dashboard data");
    } finally {
      setLoading(false);
    }
  }, [router]);

  useEffect(() => {
    setMounted(true);
    document.title = "Dashboard - QUB Admin";
    fetchDashboardData();
  }, [fetchDashboardData]);

  const formatFeatureName = (feature: string): string => {
    const names: Record<string, string> = {
      summarize: "Summarize",
      professionalize: "Professionalize",
      define: "Define",
      screen: "Screening",
    };
    return names[feature] || feature;
  };

  // ✅ FIXED: Return type string, dengan default value
  const getFeatureIcon = (feature: string): string => {
    const icons: Record<string, string> = {
      "Summarize": "📝",
      "Professionalize": "💼",
      "Define": "📖",
      "Screening": "🔍",
      "summarize": "📝",
      "professionalize": "💼",
      "define": "📖",
      "screen": "🔍",
    };
    return icons[feature] || "⚡";
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

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
          <p className="mt-4 text-gray-600">Loading dashboard data...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <PageBreadCrumb pageTitle="Dashboard" />

      <div className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Dashboard Overview</h1>
          <p className="text-gray-600 mt-1">Monitor user activity and system usage</p>
        </div>
        <button
          onClick={fetchDashboardData}
          className="px-4 py-2 text-sm font-medium text-blue-600 bg-white border border-blue-200 rounded-lg hover:bg-blue-50 transition-colors flex items-center gap-2"
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </svg>
          Refresh
        </button>
      </div>

      {error && (
        <div className="mb-6 bg-red-50 border border-red-200 rounded-lg p-4">
          <p className="text-sm text-red-800">❌ {error}</p>
        </div>
      )}

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <ComponentCard title="Total Users" className="text-center">
          <div className="flex items-center justify-center mb-2">
            <svg className="w-8 h-8 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
            </svg>
          </div>
          <p className="text-3xl font-bold text-gray-900">{stats.totalUsers.toLocaleString()}</p>
          <p className="text-xs text-gray-500 mt-1">Registered users</p>
        </ComponentCard>

        <ComponentCard title="Active Today" className="text-center">
          <div className="flex items-center justify-center mb-2">
            <svg className="w-8 h-8 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <p className="text-3xl font-bold text-green-600">{stats.activeToday.toLocaleString()}</p>
          <p className="text-xs text-gray-500 mt-1">Users logged in today</p>
        </ComponentCard>

        <ComponentCard title="Screenings Completed" className="text-center">
          <div className="flex items-center justify-center mb-2">
            <svg className="w-8 h-8 text-orange-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
            </svg>
          </div>
          <p className="text-3xl font-bold text-orange-600">{stats.screeningsCompleted.toLocaleString()}</p>
          <p className="text-xs text-gray-500 mt-1">Total screening sessions</p>
        </ComponentCard>

        <ComponentCard title="Texts Processed" className="text-center">
          <div className="flex items-center justify-center mb-2">
            <svg className="w-8 h-8 text-purple-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
          </div>
          <p className="text-3xl font-bold text-purple-600">{stats.textsProcessed.toLocaleString()}</p>
          <p className="text-xs text-gray-500 mt-1">Summarize + Professionalize</p>
        </ComponentCard>
      </div>

      <ComponentCard title="Usage Over Time" className="mb-6">
        <div className="h-[350px]">
          {mounted && <LineChartOne />}
        </div>
      </ComponentCard>

      <div className="grid grid-cols-1 xl:grid-cols-2 gap-6 mb-6">
        <ComponentCard title="Recent User Activity">
          <div className="overflow-x-auto max-h-[320px] overflow-y-auto">
            {recentActivity.length === 0 ? (
              <div className="p-8 text-center text-gray-500">
                <svg className="w-12 h-12 mx-auto mb-2 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                </svg>
                <p>No recent activity</p>
              </div>
            ) : (
              <table className="w-full">
                <thead className="bg-gray-50 sticky top-0">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">User</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Action</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Time</th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {recentActivity.map((activity, index) => (
                    <tr key={index} className="hover:bg-gray-50">
                      <td className="px-6 py-3">
                        <div className="text-sm font-medium text-gray-900">{activity.user}</div>
                      </td>
                      <td className="px-6 py-3">
                        <div className="flex items-center gap-2">
                          <span className="text-lg">{getFeatureIcon(activity.action)}</span>
                          <span className="text-sm text-gray-700">{activity.action}</span>
                        </div>
                      </td>
                      <td className="px-6 py-3 text-sm text-gray-500">{activity.time}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </ComponentCard>

        <ComponentCard title="Feature Usage Statistics">
          <div className="overflow-x-auto max-h-[320px] overflow-y-auto">
            {featureUsage.length === 0 ? (
              <div className="p-8 text-center text-gray-500">
                <p>No feature usage data</p>
              </div>
            ) : (
              <table className="w-full">
                <thead className="bg-gray-50 sticky top-0">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Feature</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Usage Count</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Trend</th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {featureUsage.map((feature, index) => (
                    <tr key={index} className="hover:bg-gray-50">
                      <td className="px-6 py-3">
                        <div className="flex items-center gap-2">
                          <span className="text-lg">{getFeatureIcon(feature.feature)}</span>
                          <span className="text-sm font-medium text-gray-900">{feature.feature}</span>
                        </div>
                      </td>
                      <td className="px-6 py-3 text-sm text-gray-700">{feature.usageCount.toLocaleString()}</td>
                      <td className="px-6 py-3">
                        <div className="flex items-center gap-2">
                          {getTrendIcon(feature.trend)}
                          <span className={`text-sm ${feature.trend === "up" ? "text-green-600" : "text-red-600"}`}>
                            {feature.trend === "up" ? "+" : "-"}{feature.trendPercent}%
                          </span>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </ComponentCard>
      </div>

      <ComponentCard title="Recently Registered Users">
        <div className="overflow-x-auto">
          {users.length === 0 ? (
            <div className="p-8 text-center text-gray-500">
              <p>No users registered yet</p>
            </div>
          ) : (
            <table className="w-full">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Display Name</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Account Hash</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Registered</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Last Login</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {users.slice(0, 5).map((user) => (
                  <tr key={user.user_id} className="hover:bg-gray-50">
                    <td className="px-6 py-4">
                      <div className="text-sm font-medium text-gray-900">{user.display_name}</div>
                    </td>
                    <td className="px-6 py-4">
                      <code className="text-xs bg-gray-100 px-2 py-1 rounded">
                        {user.account_md5.substring(0, 12)}...
                      </code>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {new Date(user.created_at).toLocaleDateString()}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {user.last_login 
                        ? new Date(user.last_login).toLocaleDateString() 
                        : "Never"}
                    </td>
                    <td className="px-6 py-4">
                      <span
                        className={`px-2.5 py-1 text-xs font-medium rounded-full border ${
                          user.is_active
                            ? "bg-green-100 text-green-800 border-green-200"
                            : "bg-red-100 text-red-800 border-red-200"
                        }`}
                      >
                        {user.is_active ? "Active" : "Inactive"}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </ComponentCard>
    </div>
  );
}