"use client";

import React, { useEffect } from "react";

// Dummy screening data
const screeningData = [
  {
    id: 1,
    userName: "Ahmad Rizki",
    userEmail: "ahmad.rizki@email.com",
    screeningDate: "2024-01-15",
    screeningType: "Dyslexia Assessment",
    score: 78,
    status: "Passed",
    flaggedIssues: ["Reading Speed", "Letter Reversal"],
  },
  {
    id: 2,
    userName: "Siti Nurhaliza",
    userEmail: "siti.nur@email.com",
    screeningDate: "2024-02-20",
    screeningType: "Phonological Awareness",
    score: 62,
    status: "Flagged",
    flaggedIssues: ["Phoneme Blending", "Rhyme Recognition"],
  },
  {
    id: 3,
    userName: "Budi Santoso",
    userEmail: "budi.santoso@email.com",
    screeningDate: "2024-03-10",
    screeningType: "Reading Comprehension",
    score: 45,
    status: "Review Required",
    flaggedIssues: ["Vocabulary", "Inference Skills", "Context Understanding"],
  },
  {
    id: 4,
    userName: "Dewi Lestari",
    userEmail: "dewi.lestari@email.com",
    screeningDate: "2024-03-25",
    screeningType: "Dyslexia Assessment",
    score: 85,
    status: "Passed",
    flaggedIssues: [],
  },
  {
    id: 5,
    userName: "Eko Prasetyo",
    userEmail: "eko.prasetyo@email.com",
    screeningDate: "2024-04-05",
    screeningType: "Writing Skills",
    score: 55,
    status: "Flagged",
    flaggedIssues: ["Spelling", "Grammar", "Sentence Structure"],
  },
];

// Summary stats
const summaryStats = {
  totalScreened: 5,
  passed: 2,
  flagged: 2,
  reviewRequired: 1,
  avgScore: 65,
  pendingReview: 1,
};

export default function DataScreeningPage() {
  // Set page title
  useEffect(() => {
    document.title = "Data Screening - QUB Admin";
  }, []);

  const handleViewDetail = (screeningId: number) => {
    alert(`Viewing screening details for ID: ${screeningId}`);
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case "Passed":
        return "bg-green-100 text-green-800 border-green-200";
      case "Flagged":
        return "bg-yellow-100 text-yellow-800 border-yellow-200";
      case "Review Required":
        return "bg-red-100 text-red-800 border-red-200";
      default:
        return "bg-gray-100 text-gray-800 border-gray-200";
    }
  };

  const getScoreColor = (score: number) => {
    if (score >= 80) return "text-green-600 font-semibold";
    if (score >= 60) return "text-yellow-600 font-semibold";
    return "text-red-600 font-semibold";
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Data Screening</h1>
          <p className="text-gray-600 mt-1">Review and manage screening results for dyslexia assessment</p>
        </div>
        <div className="flex gap-2">
          <button className="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 transition-colors">
            + New Screening
          </button>
          <button className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors">
            Export Report
          </button>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <p className="text-sm text-gray-500">Total Screened</p>
          <p className="text-2xl font-bold text-gray-900">{summaryStats.totalScreened}</p>
        </div>
        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <p className="text-sm text-gray-500">Passed</p>
          <p className="text-2xl font-bold text-green-600">{summaryStats.passed}</p>
        </div>
        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <p className="text-sm text-gray-500">Flagged</p>
          <p className="text-2xl font-bold text-yellow-600">{summaryStats.flagged}</p>
        </div>
        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <p className="text-sm text-gray-500">Review Required</p>
          <p className="text-2xl font-bold text-red-600">{summaryStats.reviewRequired}</p>
        </div>
        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <p className="text-sm text-gray-500">Avg. Score</p>
          <p className="text-2xl font-bold text-gray-900">{summaryStats.avgScore}</p>
        </div>
        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <p className="text-sm text-gray-500">Pending</p>
          <p className="text-2xl font-bold text-orange-600">{summaryStats.pendingReview}</p>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-white p-4 rounded-lg shadow-sm border">
        <div className="flex flex-wrap gap-4 items-end">
          <div className="flex-1 min-w-[200px]">
            <label className="block text-sm font-medium text-gray-700 mb-1">Search User</label>
            <input
              type="text"
              placeholder="Name or email..."
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            />
          </div>
          <div className="flex-1 min-w-[150px]">
            <label className="block text-sm font-medium text-gray-700 mb-1">Status</label>
            <select className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500">
              <option value="">All Status</option>
              <option value="passed">Passed</option>
              <option value="flagged">Flagged</option>
              <option value="review">Review Required</option>
            </select>
          </div>
          <div className="flex-1 min-w-[150px]">
            <label className="block text-sm font-medium text-gray-700 mb-1">Screening Type</label>
            <select className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500">
              <option value="">All Types</option>
              <option value="dyslexia">Dyslexia Assessment</option>
              <option value="phonological">Phonological Awareness</option>
              <option value="reading">Reading Comprehension</option>
              <option value="writing">Writing Skills</option>
            </select>
          </div>
          <button className="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 transition-colors">
            Apply Filters
          </button>
        </div>
      </div>

      {/* Screening Results Table */}
      <div className="bg-white rounded-lg shadow-sm border overflow-hidden">
        <div className="px-6 py-4 border-b flex items-center justify-between">
          <h2 className="text-lg font-semibold text-gray-900">Screening Results</h2>
          <span className="text-sm text-gray-500">{screeningData.length} results</span>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  User
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Screening Type
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Date
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Score
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Status
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Flagged Issues
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Action
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {screeningData.map((item) => (
                <tr key={item.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div>
                      <div className="text-sm font-medium text-gray-900">{item.userName}</div>
                      <div className="text-sm text-gray-500">{item.userEmail}</div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-900">{item.screeningType}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-500">{item.screeningDate}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className={`text-sm ${getScoreColor(item.score)}`}>
                      {item.score}%
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`px-2.5 py-1 text-xs font-medium rounded-full border ${getStatusColor(item.status)}`}>
                      {item.status}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex flex-wrap gap-1">
                      {item.flaggedIssues.length > 0 ? (
                        item.flaggedIssues.slice(0, 2).map((issue, idx) => (
                          <span key={idx} className="px-2 py-0.5 text-xs bg-red-50 text-red-700 rounded border border-red-200">
                            {issue}
                          </span>
                        ))
                      ) : (
                        <span className="text-sm text-gray-400">None</span>
                      )}
                      {item.flaggedIssues.length > 2 && (
                        <span className="text-xs text-gray-500">+{item.flaggedIssues.length - 2} more</span>
                      )}
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <button
                      onClick={() => handleViewDetail(item.id)}
                      className="px-3 py-1.5 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 transition-colors"
                    >
                      View Detail
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        
        {/* Pagination */}
        <div className="px-6 py-4 border-t flex items-center justify-between">
          <p className="text-sm text-gray-500">
            Showing <span className="font-medium">1</span> to <span className="font-medium">{screeningData.length}</span> of <span className="font-medium">{screeningData.length}</span> results
          </p>
          <div className="flex gap-1">
            <button className="px-3 py-1.5 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50" disabled>
              Previous
            </button>
            <button className="px-3 py-1.5 text-sm font-medium text-white bg-blue-600 border border-blue-600 rounded-lg">
              1
            </button>
            <button className="px-3 py-1.5 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50" disabled>
              Next
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}