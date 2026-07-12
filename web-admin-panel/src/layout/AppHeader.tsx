"use client";

import React, { useEffect, useState, useRef } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import Image from "next/image";
import { useSidebar } from "@/context/SidebarContext";
import { ThemeToggleButton } from "@/components/common/ThemeToggleButton";
import NotificationDropdown from "@/components/header/NotificationDropdown";
import UserDropdown from "@/components/header/UserDropdown";

// Type definitions
interface User {
  user_id: string;
  display_name: string;
  account_number?: string;
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
  const { isMobileOpen, toggleMobileSidebar } = useSidebar();
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
  const [isApplicationMenuOpen, setIsApplicationMenuOpen] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  // ✅ Cek apakah ada modal yang sedang terbuka
  const isAnyModalOpen = showAddModal || showCredentialsModal || showDetailModal;

  const handleToggle = () => {
    toggleMobileSidebar();
  };

  const toggleApplicationMenu = () => {
    setIsApplicationMenuOpen(!isApplicationMenuOpen);
  };

  useEffect(() => {
    document.title = "User Management - QUB Admin";
  }, []);

  // ✅ Lock scroll ketika modal terbuka
  useEffect(() => {
    if (isAnyModalOpen) {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "";
    }
    return () => {
      document.body.style.overflow = "";
    };
  }, [isAnyModalOpen]);

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
    <div>
      {/* ========== HEADER / TOP BAR ========== */}
      <header className="sticky top-0 flex w-full bg-white border-gray-200 z-[999] dark:border-gray-800 dark:bg-gray-900 lg:border-b">
        <div className="flex flex-col items-center justify-between grow lg:flex-row lg:px-6">
          <div className="flex items-center justify-between w-full gap-2 px-3 py-3 border-b border-gray-200 dark:border-gray-800 sm:gap-4 lg:justify-normal lg:border-b-0 lg:px-0 lg:py-4">
 <button
  className="flex lg:hidden items-center justify-center w-10 h-10 rounded-lg border border-gray-200 text-gray-500 dark:border-gray-800 dark:text-gray-400"
  onClick={handleToggle}
  aria-label="Toggle Sidebar"
>
  {isMobileOpen ? (
    <svg
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path
        fillRule="evenodd"
        clipRule="evenodd"
        d="M6.21967 7.28131C5.92678 6.98841 5.92678 6.51354 6.21967 6.22065C6.51256 5.92775 6.98744 5.92775 7.28033 6.22065L11.999 10.9393L16.7176 6.22078C17.0105 5.92789 17.4854 5.92788 17.7782 6.22078C18.0711 6.51367 18.0711 6.98855 17.7782 7.28144L13.0597 12L17.7782 16.7186C18.0711 17.0115 18.0711 17.4863 17.7782 17.7792C17.4854 18.0721 17.0105 18.0721 16.7176 17.7792L11.999 13.0607L7.28033 17.7794C6.98744 18.0722 6.51256 18.0722 6.21967 17.7794C5.92678 17.4865 5.92678 17.0116 6.21967 16.7187L10.9384 12L6.21967 7.28131Z"
        fill="currentColor"
      />
    </svg>
  ) : (
    <svg
      width="16"
      height="12"
      viewBox="0 0 16 12"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path
        fillRule="evenodd"
        clipRule="evenodd"
        d="M0.583252 1C0.583252 0.585788 0.919038 0.25 1.33325 0.25H14.6666C15.0808 0.25 15.4166 0.585786 15.4166 1C15.4166 1.41421 15.0808 1.75 14.6666 1.75L1.33325 1.75C0.919038 1.75 0.583252 1.41422 0.583252 1ZM0.583252 11C0.583252 10.5858 0.919038 10.25 1.33325 10.25H14.6666C15.0808 10.25 15.4166 10.5858 15.4166 11C15.4166 11.4142 15.0808 11.75 14.6666 11.75H1.33325C0.919038 11.75 0.583252 11.4142 0.583252 11ZM1.33325 5.25C0.919038 5.25 0.583252 5.58579 0.583252 6C0.583252 6.41421 0.919038 6.75 1.33325 6.75H7.99992C8.41413 6.75 8.74992 6.41421 8.74992 6C8.74992 5.58579 8.41413 5.25 7.99992 5.25H1.33325Z"
        fill="currentColor"
      />
    </svg>
  )}
</button>


          
            <div className="hidden lg:block">
              <form>
                <div className="relative">

                </div>
              </form>
            </div>
          </div>
          <div
            className={`${
              isApplicationMenuOpen ? "flex" : "hidden"
            } items-center justify-between w-full gap-4 px-5 py-4 lg:flex shadow-theme-md lg:justify-end lg:px-0 lg:shadow-none`}
          >
            <UserDropdown />
          </div>
        </div>
      </header>

      {/* ========== PAGE CONTENT ========== */}
      <div className="">

        {/* ========== ERROR ALERT ========== */}
        {error && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-4">
            <p className="text-sm text-red-800">❌ {error}</p>
          </div>
        )}


        {/* ========== USERS TABLE ========== */}
        
      </div>

      {/* ========== ADD USER MODAL ========== */}
      {showAddModal && (
        <div className="fixed inset-0 flex items-center justify-center z-[10000]">
          {/* Backdrop */}
          <div 
            className="absolute inset-0 bg-black/60 backdrop-blur-sm"
            onClick={() => setShowAddModal(false)}
          />
          {/* Modal Content */}
          <div className="relative bg-white rounded-lg p-6 max-w-md w-full mx-4 shadow-2xl">
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

      {/* ========== CREDENTIALS DISPLAY MODAL ========== */}
      {showCredentialsModal && createdCredentials.length > 0 && (
        <div className="fixed inset-0 flex items-center justify-center z-[10000]">
          {/* Backdrop */}
          <div 
            className="absolute inset-0 bg-black/60 backdrop-blur-sm"
            onClick={() => setShowCredentialsModal(false)}
          />
          {/* Modal Content */}
          <div className="relative bg-white rounded-lg p-6 max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto shadow-2xl">
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

      {/* ========== DETAIL MODAL ========== */}
      {showDetailModal && selectedUser && (
        <div className="fixed inset-0 flex items-center justify-center z-[10000]">
          {/* Backdrop */}
          <div 
            className="absolute inset-0 bg-black/60 backdrop-blur-sm"
            onClick={() => setShowDetailModal(false)}
          />
          {/* Modal Content */}
          <div className="relative bg-white rounded-lg p-6 max-w-lg w-full mx-4 shadow-2xl">
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
                  <p className="text-xl font-mono bg-green-50 p-3 rounded flex-1 border border-green-200 font-bold text-green-700 tracking-widest">
                    {selectedUser.account_number || 'Not Available'}
                  </p>
                  {selectedUser.account_number && (
                    <button
                      onClick={() => copyToClipboard(selectedUser.account_number!)}
                      className="p-2 text-green-600 hover:bg-green-50 rounded"
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