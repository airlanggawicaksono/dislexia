"use client";

import React, { useEffect, useState, useCallback } from "react";
import { useRouter } from "next/navigation";

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

type FeatureTab = "summarize" | "professionalize" | "define" | "screen";

export default function DataScreeningPage() {
  const router = useRouter();
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [authChecked, setAuthChecked] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState<string>("");
  const [error, setError] = useState<string | null>(null);

  // Detail modal states
  const [showDetailModal, setShowDetailModal] = useState(false);
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [activeTab, setActiveTab] = useState<FeatureTab>("screen");
  const [userHistory, setUserHistory] = useState<HistoryItem[]>([]);
  const [historyLoading, setHistoryLoading] = useState(false);

  // Summary stats
  const [stats, setStats] = useState({
    totalUsers: 0,
    activeUsers: 0,
    totalHistory: 0,
    screenings: 0,
  });

  useEffect(() => {
    document.title = "User Activity - QUB Admin";
  }, []);

  // ✅ Check auth
  useEffect(() => {
    const token = localStorage.getItem("admin_token");
    const adminInfoStr = localStorage.getItem("admin_info");

    if (!token) {
      router.push("/signin");
      return;
    }

    if (adminInfoStr) {
      try {
        const adminInfo = JSON.parse(adminInfoStr);
        if (adminInfo.must_change_password) {
          router.push("/change-password?first_login=true");
          return;
        }
      } catch (e) {
        console.error("Failed to parse admin info:", e);
      }
    }

    setAuthChecked(true);
  }, [router]);

  // ✅ Fetch users
  const fetchUsers = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const token = localStorage.getItem("admin_token");

      if (!token) {
        router.push("/signin");
        return;
      }

      const [usersRes, historyRes] = await Promise.all([
        fetch(`/api/proxy/api/v1/admin/users`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
        fetch(`/api/proxy/api/v1/admin/history`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
      ]);

      if (usersRes.status === 401 || historyRes.status === 401) {
        localStorage.removeItem("admin_token");
        localStorage.removeItem("admin_info");
        document.cookie = "admin_token=; path=/; max-age=0";
        router.push("/signin");
        return;
      }

      if (!usersRes.ok || !historyRes.ok) {
        throw new Error("Failed to fetch data");
      }

      const usersData = await usersRes.json();
      const historyData = await historyRes.json();

      const usersList: User[] = usersData.items || [];
      const historyList: HistoryItem[] = historyData.items || [];

      setUsers(usersList);

      // Calculate stats
      const activeUsers = usersList.filter((u) => u.is_active).length;
      const screenings = historyList.filter((h) => h.feature === "screen").length;

      setStats({
        totalUsers: usersData.total || usersList.length,
        activeUsers,
        totalHistory: historyData.total || historyList.length,
        screenings,
      });
    } catch (err: any) {
      console.error("Error fetching users:", err);
      setError(err.message || "Failed to load data");
    } finally {
      setLoading(false);
    }
  }, [router]);

  useEffect(() => {
    if (authChecked) {
      fetchUsers();
    }
  }, [authChecked, fetchUsers]);

  // ✅ Fetch user history when detail modal opens
  const fetchUserHistory = async (user: User, feature: FeatureTab) => {
    try {
      setHistoryLoading(true);
      const token = localStorage.getItem("admin_token");

      if (!token) return;

      const response = await fetch(
        `/api/proxy/api/v1/admin/history?user=${user.account_md5}&feature=${feature}`,
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );

      if (!response.ok) {
        throw new Error("Failed to fetch history");
      }

      const data = await response.json();
      setUserHistory(data.items || []);
    } catch (err: any) {
      console.error("Error fetching history:", err);
      setUserHistory([]);
    } finally {
      setHistoryLoading(false);
    }
  };

  const handleViewDetail = (user: User) => {
    setSelectedUser(user);
    setActiveTab("screen");
    setShowDetailModal(true);
    fetchUserHistory(user, "screen");
  };

  const handleTabChange = (tab: FeatureTab) => {
    setActiveTab(tab);
    if (selectedUser) {
      fetchUserHistory(selectedUser, tab);
    }
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString("en-US", {
      year: "numeric",
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  };

  const formatShortDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString("en-US", {
      month: "short",
      day: "numeric",
      year: "numeric",
    });
  };

  // Filter users
  const filteredUsers = users.filter((user) => {
    const matchesSearch =
      user.display_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      user.account_md5.toLowerCase().includes(searchQuery.toLowerCase());

    const matchesStatus =
      statusFilter === "" ||
      (statusFilter === "active" && user.is_active) ||
      (statusFilter === "inactive" && !user.is_active);

    return matchesSearch && matchesStatus;
  });

  // Get feature icon and color
  const getFeatureInfo = (feature: string) => {
    switch (feature) {
      case "summarize":
        return { icon: "📝", color: "bg-blue-100 text-blue-800", label: "Summarize" };
      case "professionalize":
        return { icon: "💼", color: "bg-purple-100 text-purple-800", label: "Professionalize" };
      case "define":
        return { icon: "📖", color: "bg-green-100 text-green-800", label: "Define" };
      case "screen":
        return { icon: "🔍", color: "bg-orange-100 text-orange-800", label: "Screening" };
      default:
        return { icon: "⚡", color: "bg-gray-100 text-gray-800", label: feature };
    }
  };

  // Truncate text
  const truncateText = (text: string, maxLength: number = 150) => {
    if (!text) return "";
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength) + "...";
  };

  if (!authChecked) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-center">
          <div className="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
          <p className="mt-4 text-gray-600">Checking authentication...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">User Activity</h1>
          <p className="text-gray-600 mt-1">
            View user activity history across all features
          </p>
        </div>
        <button
          onClick={fetchUsers}
          className="px-4 py-2 text-sm font-medium text-blue-600 bg-white border border-blue-200 rounded-lg hover:bg-blue-50 transition-colors flex items-center gap-2"
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </svg>
          Refresh
        </button>
      </div>

      {/* Error Alert */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <p className="text-sm text-red-800">❌ {error}</p>
        </div>
      )}

      {/* Summary Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-blue-100 rounded-lg">
              <svg className="w-6 h-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
              </svg>
            </div>
            <div>
              <p className="text-sm text-gray-500">Total Users</p>
              <p className="text-2xl font-bold text-gray-900">{stats.totalUsers}</p>
            </div>
          </div>
        </div>

        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-green-100 rounded-lg">
              <svg className="w-6 h-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <div>
              <p className="text-sm text-gray-500">Active Users</p>
              <p className="text-2xl font-bold text-green-600">{stats.activeUsers}</p>
            </div>
          </div>
        </div>

        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-purple-100 rounded-lg">
              <svg className="w-6 h-6 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
              </svg>
            </div>
            <div>
              <p className="text-sm text-gray-500">Total Activities</p>
              <p className="text-2xl font-bold text-purple-600">{stats.totalHistory}</p>
            </div>
          </div>
        </div>

        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-orange-100 rounded-lg">
              <svg className="w-6 h-6 text-orange-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
            </div>
            <div>
              <p className="text-sm text-gray-500">Screenings</p>
              <p className="text-2xl font-bold text-orange-600">{stats.screenings}</p>
            </div>
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-white p-4 rounded-lg shadow-sm border">
        <div className="flex flex-wrap gap-4 items-end">
          <div className="flex-1 min-w-[200px]">
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Search User
            </label>
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Display name or account hash..."
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            />
          </div>
          <div className="flex-1 min-w-[150px]">
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Status
            </label>
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="">All Status</option>
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
            </select>
          </div>
        </div>
      </div>

      {/* Users Table */}
      <div className="bg-white rounded-lg shadow-sm border overflow-hidden">
        <div className="px-6 py-4 border-b flex items-center justify-between">
          <h2 className="text-lg font-semibold text-gray-900">User List</h2>
          <span className="text-sm text-gray-500">
            {filteredUsers.length} users
          </span>
        </div>
        <div className="overflow-x-auto">
          {loading ? (
            <div className="p-8 text-center">
              <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
              <p className="mt-2 text-gray-500">Loading users...</p>
            </div>
          ) : (
            <table className="w-full">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Display Name
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Account Hash
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Registered
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Last Login
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {filteredUsers.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="px-6 py-8 text-center text-gray-500">
                      No users found
                    </td>
                  </tr>
                ) : (
                  filteredUsers.map((user) => (
                    <tr key={user.user_id} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-medium text-gray-900">
                          {user.display_name}
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <code className="text-xs bg-gray-100 px-2 py-1 rounded font-mono">
                          {user.account_md5.substring(0, 12)}...
                        </code>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-500">
                          {formatShortDate(user.created_at)}
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-500">
                          {user.last_login ? formatShortDate(user.last_login) : "Never"}
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
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
                      <td className="px-6 py-4 whitespace-nowrap text-sm">
                        <button
                          onClick={() => handleViewDetail(user)}
                          className="px-3 py-1.5 text-xs font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 transition-colors flex items-center gap-1"
                        >
                          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                          </svg>
                          View Activity
                        </button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          )}
        </div>
      </div>

      {/* ✅ Detail Modal with Tabs */}
      {showDetailModal && selectedUser && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg w-full max-w-5xl max-h-[90vh] overflow-hidden flex flex-col">
            {/* Modal Header */}
            <div className="px-6 py-4 border-b flex items-center justify-between bg-gray-50">
              <div>
                <h3 className="text-lg font-semibold text-gray-900">
                  User Activity: {selectedUser.display_name}
                </h3>
                <p className="text-sm text-gray-500 mt-1">
                  Account Hash: <code className="bg-gray-200 px-2 py-0.5 rounded text-xs">{selectedUser.account_md5.substring(0, 16)}...</code>
                </p>
              </div>
              <button
                onClick={() => setShowDetailModal(false)}
                className="text-gray-400 hover:text-gray-600 transition-colors"
              >
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            {/* ✅ Tabs */}
            <div className="border-b bg-white">
              <div className="flex">
                {(["screen", "summarize", "professionalize", "define"] as FeatureTab[]).map((tab) => {
                  const info = getFeatureInfo(tab);
                  return (
                    <button
                      key={tab}
                      onClick={() => handleTabChange(tab)}
                      className={`px-6 py-3 text-sm font-medium border-b-2 transition-colors flex items-center gap-2 ${
                        activeTab === tab
                          ? "border-blue-600 text-blue-600"
                          : "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
                      }`}
                    >
                      <span className="text-lg">{info.icon}</span>
                      {info.label}
                    </button>
                  );
                })}
              </div>
            </div>

            {/* ✅ Tab Content */}
            <div className="flex-1 overflow-y-auto p-6">
              {historyLoading ? (
                <div className="flex items-center justify-center py-12">
                  <div className="text-center">
                    <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
                    <p className="mt-2 text-gray-500">Loading history...</p>
                  </div>
                </div>
              ) : userHistory.length === 0 ? (
                <div className="text-center py-12">
                  <div className="inline-flex items-center justify-center w-16 h-16 bg-gray-100 rounded-full mb-4">
                    <svg className="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                    </svg>
                  </div>
                  <p className="text-gray-500 text-lg font-medium">No {getFeatureInfo(activeTab).label} history</p>
                  <p className="text-gray-400 text-sm mt-1">This user hasn't used this feature yet</p>
                </div>
              ) : (
                <div className="space-y-4">
                  <div className="flex items-center justify-between mb-4">
                    <p className="text-sm text-gray-600">
                      Showing <strong>{userHistory.length}</strong> {getFeatureInfo(activeTab).label} records
                    </p>
                  </div>

                  {userHistory.map((item) => {
                    const featureInfo = getFeatureInfo(item.feature);
                    return (
                      <div
                        key={item.id}
                        className="border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow"
                      >
                        {/* Header */}
                        <div className="flex items-center justify-between mb-3 pb-3 border-b">
                          <div className="flex items-center gap-2">
                            <span className={`px-2.5 py-1 text-xs font-medium rounded-full ${featureInfo.color}`}>
                              {featureInfo.icon} {featureInfo.label}
                            </span>
                            <span className="text-xs text-gray-500">
                              Session: <code className="bg-gray-100 px-1.5 py-0.5 rounded">{item.session_id.substring(0, 8)}...</code>
                            </span>
                          </div>
                          <span className="text-xs text-gray-500">
                            {formatDate(item.created_at)}
                          </span>
                        </div>

                        {/* Input */}
                        <div className="mb-3">
                          <p className="text-xs font-medium text-gray-500 uppercase mb-1">Input Text</p>
                          <div className="bg-gray-50 border border-gray-200 rounded p-3 text-sm text-gray-800 max-h-32 overflow-y-auto">
                            {truncateText(item.input_text, 300)}
                          </div>
                        </div>

                        {/* Output */}
                        {item.output_text && (
                          <div>
                            <p className="text-xs font-medium text-gray-500 uppercase mb-1">Output</p>
                            <div className="bg-blue-50 border border-blue-200 rounded p-3 text-sm text-gray-800 max-h-32 overflow-y-auto">
                              {truncateText(item.output_text, 300)}
                            </div>
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>
              )}
            </div>

            {/* Modal Footer */}
            <div className="px-6 py-4 border-t bg-gray-50 flex justify-end">
              <button
                onClick={() => setShowDetailModal(false)}
                className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}