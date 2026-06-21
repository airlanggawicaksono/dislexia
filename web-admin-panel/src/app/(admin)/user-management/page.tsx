"use client";

import React, { useEffect, useState } from "react";
import { useRouter } from "next/navigation";

// Type definitions
interface User {
  user_id: string;
  display_name: string;
  account_number?: string; // ✅ Made optional (API may not return this)
  account_md5: string;
  is_active: boolean;
  created_at: string;
  last_login: string;
}

interface CreateUserResponse {
  user_id: string;
  account_number: string;
  display_name: string;
}

export default function UserManagementPage() {
  const router = useRouter();
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [authChecked, setAuthChecked] = useState(false);
  const [showAddModal, setShowAddModal] = useState(false);
  const [showDetailModal, setShowDetailModal] = useState(false);
  const [showCredentialsModal, setShowCredentialsModal] = useState(false);
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [bulkCount, setBulkCount] = useState(1);
  const [createdCredentials, setCreatedCredentials] = useState<CreateUserResponse[]>([]);
  const [searchQuery, setSearchQuery] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [copiedId, setCopiedId] = useState<string | null>(null);

  useEffect(() => {
    document.title = "User Management - QUB Admin";
  }, []);

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

  useEffect(() => {
    if (authChecked) {
      fetchUsers();
    }
  }, [authChecked]);

  const fetchUsers = async () => {
    try {
      setLoading(true);
      setError(null);
      const token = localStorage.getItem("admin_token");
      
      if (!token) {
        router.push("/signin");
        return;
      }

      const response = await fetch(`/api/proxy/api/v1/admin/users`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (response.status === 401) {
        localStorage.removeItem("admin_token");
        localStorage.removeItem("admin_info");
        document.cookie = "admin_token=; path=/; max-age=0";
        router.push("/signin");
        return;
      }

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.detail || `HTTP ${response.status}`);
      }

      const data = await response.json();
      setUsers(data.items || []);
    } catch (error: any) {
      console.error("Error fetching users:", error);
      setError(error.message || "Failed to load users");
    } finally {
      setLoading(false);
    }
  };

  const handleAddUser = async () => {
    try {
      setError(null);
      const token = localStorage.getItem("admin_token");
      
      if (!token) {
        router.push("/signin");
        return;
      }

      const credentials: CreateUserResponse[] = [];

      for (let i = 0; i < bulkCount; i++) {
        const response = await fetch(`/api/proxy/api/v1/admin/users`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({}),
        });

        if (response.status === 401) {
          localStorage.removeItem("admin_token");
          localStorage.removeItem("admin_info");
          document.cookie = "admin_token=; path=/; max-age=0";
          router.push("/signin");
          return;
        }

        if (!response.ok) {
          const errorData = await response.json().catch(() => ({}));
          throw new Error(errorData.detail || `Failed to create user ${i + 1}`);
        }

        const data = await response.json();
        credentials.push(data);
      }

      setCreatedCredentials(credentials);
      setShowAddModal(false);
      setShowCredentialsModal(true);
      
      await fetchUsers();
    } catch (error: any) {
      console.error("Error creating users:", error);
      setError(error.message || "Failed to create users");
    }
  };

  const handleDeleteUser = async (userId: string, displayName: string) => {
    if (!confirm(`Are you sure you want to delete user "${displayName}"?\n\nThis action CANNOT be undone!`)) {
      return;
    }

    try {
      setError(null);
      const token = localStorage.getItem("admin_token");
      
      if (!token) {
        router.push("/signin");
        return;
      }

      const response = await fetch(`/api/proxy/api/v1/admin/users/${userId}`, {
        method: "DELETE",
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (response.status === 401) {
        localStorage.removeItem("admin_token");
        localStorage.removeItem("admin_info");
        document.cookie = "admin_token=; path=/; max-age=0";
        router.push("/signin");
        return;
      }

      if (response.status === 204) {
        await fetchUsers();
        return;
      }

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.detail || "Failed to delete user");
      }

      await fetchUsers();
    } catch (error: any) {
      console.error("Error deleting user:", error);
      setError(error.message || "Failed to delete user");
    }
  };

  const handleViewDetail = (user: User) => {
    setSelectedUser(user);
    setShowDetailModal(true);
  };

  const copyToClipboard = (text: string, id?: string) => {
    navigator.clipboard.writeText(text);
    if (id) {
      setCopiedId(id);
      setTimeout(() => setCopiedId(null), 2000);
    }
  };

  const copyAllCredentials = () => {
    const text = createdCredentials
      .map((c, idx) => `${idx + 1}. ${c.display_name}\n   Access Code: ${c.account_number}`)
      .join("\n\n");
    navigator.clipboard.writeText(text);
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

  // ✅ FIXED: Safe filter with optional chaining
  const filteredUsers = users.filter((user) => {
    const query = searchQuery.toLowerCase();
    const displayName = user.display_name?.toLowerCase() || "";
    const accountNumber = user.account_number?.toLowerCase() || "";
    const accountMd5 = user.account_md5?.toLowerCase() || "";
    
    return (
      displayName.includes(query) ||
      accountNumber.includes(query) ||
      accountMd5.includes(query)
    );
  });

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
          <h1 className="text-2xl font-bold text-gray-900">User Management</h1>
          <p className="text-gray-600 mt-1">
            Manage end-user accounts and access credentials
          </p>
        </div>
        <div className="flex gap-2">
          <button
            onClick={() => setShowAddModal(true)}
            className="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 transition-colors"
          >
            + Add User
          </button>
        </div>
      </div>

      {/* Error Alert */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <p className="text-sm text-red-800">❌ {error}</p>
        </div>
      )}

      {/* Search */}
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
              placeholder="Display name, access code, or account hash..."
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            />
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
                    Access Code
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Created At
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
                    <td colSpan={5} className="px-6 py-8 text-center text-gray-500">
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
                        <div className="flex items-center gap-2">
                          <code className="text-sm bg-blue-50 text-blue-700 px-3 py-1.5 rounded font-mono font-semibold border border-blue-200">
                            {user.account_number || '••••••'}
                          </code>
                          {user.account_number && (
                            <button
                              onClick={() => copyToClipboard(user.account_number!, user.user_id)}
                              className={`p-1.5 rounded transition-colors ${
                                copiedId === user.user_id
                                  ? 'text-green-600 bg-green-50'
                                  : 'text-gray-400 hover:text-gray-600 hover:bg-gray-100'
                              }`}
                              title="Copy access code"
                            >
                              {copiedId === user.user_id ? (
                                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                                </svg>
                              ) : (
                                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                                </svg>
                              )}
                            </button>
                          )}
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-500">
                          {formatDate(user.created_at)}
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
                        <div className="flex gap-2">
                          <button
                            onClick={() => handleViewDetail(user)}
                            className="px-3 py-1.5 text-xs font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 transition-colors"
                          >
                            Detail
                          </button>
                          <button
                            onClick={() =>
                              handleDeleteUser(user.user_id, user.display_name)
                            }
                            className="px-3 py-1.5 text-xs font-medium text-white bg-red-600 rounded-lg hover:bg-red-700 transition-colors"
                          >
                            Delete
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          )}
        </div>
      </div>

      {/* Add User Modal */}
      {showAddModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-md w-full mx-4">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">
              Add New User(s)
            </h3>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Number of Users
                </label>
                <input
                  type="number"
                  min="1"
                  max="50"
                  value={bulkCount}
                  onChange={(e) => setBulkCount(parseInt(e.target.value) || 1)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                />
                <p className="text-xs text-gray-500 mt-1">
                  You will create {bulkCount} user{bulkCount > 1 ? "s" : ""} at once
                </p>
              </div>
              <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-3">
                <p className="text-sm text-yellow-800">
                  ⚠️ <strong>IMPORTANT:</strong> Access codes will be displayed
                  only once after creation. Make sure to save them!
                </p>
              </div>
            </div>
            <div className="flex gap-2 mt-6">
              <button
                onClick={() => setShowAddModal(false)}
                className="flex-1 px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleAddUser}
                className="flex-1 px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 transition-colors"
              >
                Create {bulkCount} User{bulkCount > 1 ? "s" : ""}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Credentials Display Modal */}
      {showCredentialsModal && createdCredentials.length > 0 && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto">
            <div className="bg-red-50 border-2 border-red-300 rounded-lg p-4 mb-4">
              <h3 className="text-lg font-bold text-red-800 mb-2">
                🚨 IMPORTANT! SAVE THESE CREDENTIALS!
              </h3>
              <p className="text-sm text-red-700">
                The access codes below are <strong>SHOWN ONLY ONCE</strong> and CANNOT be retrieved later.
                Share them with users via WhatsApp/Email/Paper immediately.
              </p>
            </div>

            <div className="space-y-3 mb-4">
              {createdCredentials.map((cred, idx) => (
                <div key={cred.user_id} className="border border-gray-200 rounded-lg p-4 bg-gray-50">
                  <div className="flex items-start justify-between mb-2">
                    <div>
                      <p className="text-xs text-gray-500">User {idx + 1}</p>
                      <p className="text-lg font-semibold text-gray-900">{cred.display_name}</p>
                    </div>
                    <button
                      onClick={() => copyToClipboard(cred.account_number)}
                      className="px-3 py-1 text-xs font-medium text-blue-600 bg-white border border-blue-300 rounded hover:bg-blue-50"
                    >
                      📋 Copy
                    </button>
                  </div>
                  <div className="bg-white border border-gray-300 rounded p-3">
                    <p className="text-xs text-gray-500 mb-1">Access Code (Login Credential):</p>
                    <p className="text-2xl font-mono font-bold text-blue-600 tracking-wider">
                      {cred.account_number}
                    </p>
                  </div>
                </div>
              ))}
            </div>

            <div className="flex gap-2">
              <button
                onClick={copyAllCredentials}
                className="flex-1 px-4 py-2 text-sm font-medium text-white bg-green-600 rounded-lg hover:bg-green-700 transition-colors"
              >
                📋 Copy All Credentials
              </button>
              <button
                onClick={() => {
                  setShowCredentialsModal(false);
                  setCreatedCredentials([]);
                }}
                className="flex-1 px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
              >
                Done
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Detail Modal */}
      {showDetailModal && selectedUser && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-lg w-full mx-4">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">
              User Details
            </h3>
            <div className="space-y-3">
              <div>
                <label className="text-sm font-medium text-gray-500">User ID</label>
                <p className="text-sm text-gray-900 font-mono bg-gray-50 p-2 rounded">
                  {selectedUser.user_id}
                </p>
              </div>
              <div>
                <label className="text-sm font-medium text-gray-500">Display Name</label>
                <p className="text-sm text-gray-900">{selectedUser.display_name}</p>
              </div>
              <div>
                <label className="text-sm font-medium text-gray-500">Access Code</label>
                <div className="flex items-center gap-2">
                  <p className="text-sm text-gray-900 font-mono bg-blue-50 p-2 rounded flex-1 border border-blue-200 font-semibold text-blue-700">
                    {selectedUser.account_number || '••••••'}
                  </p>
                  {selectedUser.account_number && (
                    <button
                      onClick={() => copyToClipboard(selectedUser.account_number!)}
                      className="p-2 text-blue-600 hover:bg-blue-50 rounded"
                      title="Copy access code"
                    >
                      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                      </svg>
                    </button>
                  )}
                </div>
              </div>
              <div>
                <label className="text-sm font-medium text-gray-500">Account Hash (MD5)</label>
                <p className="text-sm text-gray-900 font-mono bg-gray-50 p-2 rounded break-all">
                  {selectedUser.account_md5}
                </p>
              </div>
              <div>
                <label className="text-sm font-medium text-gray-500">Status</label>
                <p>
                  <span
                    className={`px-2.5 py-1 text-xs font-medium rounded-full border ${
                      selectedUser.is_active
                        ? "bg-green-100 text-green-800 border-green-200"
                        : "bg-red-100 text-red-800 border-red-200"
                    }`}
                  >
                    {selectedUser.is_active ? "Active" : "Inactive"}
                  </span>
                </p>
              </div>
              <div>
                <label className="text-sm font-medium text-gray-500">Created At</label>
                <p className="text-sm text-gray-900">{formatDate(selectedUser.created_at)}</p>
              </div>
              <div>
                <label className="text-sm font-medium text-gray-500">Last Login</label>
                <p className="text-sm text-gray-900">
                  {selectedUser.last_login ? formatDate(selectedUser.last_login) : "Never"}
                </p>
              </div>
            </div>
            <div className="mt-6">
              <button
                onClick={() => setShowDetailModal(false)}
                className="w-full px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
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