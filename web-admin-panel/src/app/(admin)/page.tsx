// src/app/(admin)/page.tsx
'use client';

import React, { useEffect, useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import ComponentCard from "@/components/common/ComponentCard";
import PageBreadCrumb from "@/components/common/PageBreadCrumb";

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
  dateTime: string;
  feature: string;
}

interface FeatureUsage {
  feature: string;
  usageCount: number;
  trend: "up" | "down";
  trendPercent: number;
}

interface DailyUsage {
  date: string;
  dateSort: string;
  summarize: number;
  professionalize: number;
  define: number;
  screen: number;
  total: number;
}

// ✅ Tooltip state type
interface TooltipState {
  visible: boolean;
  x: number;
  y: number;
  data: DailyUsage | null;
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
  const [dailyUsage, setDailyUsage] = useState<DailyUsage[]>([]);

  // ✅ State untuk tooltip fixed positioning
  const [tooltip, setTooltip] = useState<TooltipState>({
    visible: false,
    x: 0,
    y: 0,
    data: null,
  });

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

      const screeningSessions = new Set(
        historyList
          .filter((item) => item.feature === "screen")
          .map((item) => item.session_id)
      ).size;

      const textsProcessed = historyList.filter(
        (item) =>
          item.feature === "summarize" || item.feature === "professionalize"
      ).length;

      setStats({
        totalUsers: usersData.total || usersList.length,
        activeToday,
        screeningsCompleted: screeningSessions,
        textsProcessed,
      });

      const activity: UserActivity[] = historyList
        .slice(0, 10)
        .map((item) => {
          const user = usersList.find((u) => u.user_id === item.user_id);
          const dateTime = new Date(item.created_at);
          return {
            user: user?.display_name || "Unknown User",
            action: formatFeatureName(item.feature),
            dateTime: dateTime.toLocaleString("en-US", {
              month: "short",
              day: "numeric",
              year: "numeric",
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

      const usageByDate: Record<string, DailyUsage> = {};

      historyList.forEach((item) => {
        const dateObj = new Date(item.created_at);
        const dateKey = dateObj.toISOString().split('T')[0];
        const dateDisplay = dateObj.toLocaleDateString("en-US", {
          month: "short",
          day: "numeric",
          year: "numeric",
        });

        if (!usageByDate[dateKey]) {
          usageByDate[dateKey] = {
            date: dateDisplay,
            dateSort: dateKey,
            summarize: 0,
            professionalize: 0,
            define: 0,
            screen: 0,
            total: 0,
          };
        }

        usageByDate[dateKey][item.feature]++;
        usageByDate[dateKey].total++;
      });

      const dailyUsageArray = Object.values(usageByDate)
        .sort((a, b) => a.dateSort.localeCompare(b.dateSort))
        .slice(-7);

      setDailyUsage(dailyUsageArray);
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

  // ✅ Handler untuk tooltip dengan smart positioning
  const handleBarMouseEnter = (e: React.MouseEvent<HTMLDivElement>, day: DailyUsage) => {
    const rect = e.currentTarget.getBoundingClientRect();
    const tooltipWidth = 200; // perkiraan lebar tooltip
    const tooltipHeight = 140; // perkiraan tinggi tooltip
    const offset = 12; // jarak dari bar

    // Hitung posisi X (tengah bar)
    let x = rect.left + rect.width / 2;

    // Hitung posisi Y (di atas bar)
    let y = rect.top - offset;

    // ✅ Smart positioning: cegah tooltip keluar viewport
    // Jika terlalu dekat dengan tepi kiri
    if (x - tooltipWidth / 2 < 10) {
      x = tooltipWidth / 2 + 10;
    }
    // Jika terlalu dekat dengan tepi kanan
    if (x + tooltipWidth / 2 > window.innerWidth - 10) {
      x = window.innerWidth - tooltipWidth / 2 - 10;
    }
    // Jika terlalu dekat dengan tepi atas (bar tinggi) → tampilkan di bawah
    let showBelow = false;
    if (y - tooltipHeight < 10) {
      y = rect.bottom + offset;
      showBelow = true;
    }

    setTooltip({
      visible: true,
      x,
      y,
      data: day,
    });

    // Simpan info posisi untuk transform
    (e.currentTarget as any).dataset.showBelow = showBelow ? "true" : "false";
  };

  const handleBarMouseLeave = () => {
    setTooltip((prev) => ({ ...prev, visible: false, data: null }));
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

        <ComponentCard title="Screening Sessions" className="text-center">
          <div className="flex items-center justify-center mb-2">
            <svg className="w-8 h-8 text-orange-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
            </svg>
          </div>
          <p className="text-3xl font-bold text-orange-600">{stats.screeningsCompleted.toLocaleString()}</p>
          <p className="text-xs text-gray-500 mt-1">Unique screening sessions</p>
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

      {/* ✅ Usage chart with FIXED POSITIONED TOOLTIP */}
      <ComponentCard title="Usage Over Time (Last 7 Days)" className="mb-6">
        <div className="h-[350px]">
          {dailyUsage.length === 0 ? (
            <div className="h-full flex items-center justify-center text-gray-500">
              <p>No usage data available</p>
            </div>
          ) : (
            (() => {
              const maxTotal = Math.max(...dailyUsage.map(d => d.total), 1);
              const BAR_MAX_HEIGHT = 220;

              return (
                <div className="h-full flex items-end justify-between gap-2 px-4 pb-16 pt-8">
                  {dailyUsage.map((day, index) => {
                    const barHeight = Math.max((day.total / maxTotal) * BAR_MAX_HEIGHT, 8);

                    return (
                      <div key={index} className="flex-1 flex flex-col items-center gap-2 min-w-[90px]">
                        <div className="text-xs font-bold text-gray-700 mb-1">{day.total}</div>
                        <div
                          className="w-full bg-gradient-to-t from-blue-500 to-blue-400 rounded-t-lg transition-all hover:from-blue-600 hover:to-blue-500 cursor-pointer"
                          style={{ height: `${barHeight}px` }}
                          onMouseEnter={(e) => handleBarMouseEnter(e, day)}
                          onMouseLeave={handleBarMouseLeave}
                        />
                        <div className="text-xs text-gray-600 font-medium text-center leading-tight">
                          {day.date}
                        </div>
                      </div>
                    );
                  })}
                </div>
              );
            })()
          )}
        </div>
      </ComponentCard>

      {/* ✅ FIXED TOOLTIP - dirender di root, tidak akan pernah terpotong */}
      {tooltip.visible && tooltip.data && (
        <div
          className="fixed z-50 bg-gray-900 text-white text-xs rounded-lg py-2.5 px-3 pointer-events-none shadow-2xl border border-gray-700"
          style={{
            left: tooltip.x,
            top: tooltip.y,
            // Smart transform: di atas bar atau di bawah bar
            transform: (tooltip.y < 160)
              ? 'translate(-50%, 0)'    // Bar terlalu tinggi → tooltip di bawah cursor
              : 'translate(-50%, -100%)', // Normal → tooltip di atas cursor
            minWidth: '180px',
          }}
        >
          <div className="font-bold mb-1.5 border-b border-gray-700 pb-1.5 text-sm">
            {tooltip.data.date}
          </div>
          <div className="space-y-0.5">
            <div className="flex justify-between gap-4">
              <span>📝 Summarize:</span>
              <span className="font-semibold">{tooltip.data.summarize}</span>
            </div>
            <div className="flex justify-between gap-4">
              <span>💼 Professionalize:</span>
              <span className="font-semibold">{tooltip.data.professionalize}</span>
            </div>
            <div className="flex justify-between gap-4">
              <span>📖 Define:</span>
              <span className="font-semibold">{tooltip.data.define}</span>
            </div>
            <div className="flex justify-between gap-4">
              <span>🔍 Screening:</span>
              <span className="font-semibold">{tooltip.data.screen}</span>
            </div>
          </div>
          <div className="font-bold mt-1.5 pt-1.5 border-t border-gray-700 flex justify-between gap-4">
            <span>Total:</span>
            <span>{tooltip.data.total}</span>
          </div>
        </div>
      )}

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
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date & Time</th>
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
                      <td className="px-6 py-3 text-sm text-gray-500 whitespace-nowrap">{activity.dateTime}</td>
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
                      {new Date(user.created_at).toLocaleDateString("en-US", {
                        month: "short",
                        day: "numeric",
                        year: "numeric",
                      })}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {user.last_login
                        ? new Date(user.last_login).toLocaleDateString("en-US", {
                            month: "short",
                            day: "numeric",
                            year: "numeric",
                          })
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