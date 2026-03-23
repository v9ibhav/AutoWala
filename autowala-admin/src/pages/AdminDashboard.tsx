import React from 'react';
import {
  ChartBarIcon,
  UsersIcon,
  TruckIcon,
  CurrencyRupeeIcon,
  MapPinIcon,
  ExclamationTriangleIcon,
  CheckCircleIcon,
  ClockIcon
} from '@heroicons/react/24/outline';
import {
  AreaChart,
  Area,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
} from 'recharts';

// Mock data for demonstration
const dashboardStats = {
  totalUsers: 15420,
  activeRiders: 1247,
  todayRides: 892,
  totalRevenue: 1580000,
  userGrowth: 12.5,
  riderGrowth: 8.3,
  rideGrowth: 15.2,
  revenueGrowth: 22.1,
};

const recentRides = [
  { id: '1', user: 'Priya Sharma', rider: 'Rajesh Kumar', amount: 45, status: 'completed', time: '2 min ago' },
  { id: '2', user: 'Amit Patel', rider: 'Suresh Shah', amount: 32, status: 'in_progress', time: '5 min ago' },
  { id: '3', user: 'Sneha Singh', rider: 'Mahesh Yadav', amount: 28, status: 'completed', time: '8 min ago' },
  { id: '4', user: 'Rahul Gupta', rider: 'Vijay Singh', amount: 55, status: 'completed', time: '12 min ago' },
  { id: '5', user: 'Kavita Jain', rider: 'Ramesh Kumar', amount: 41, status: 'cancelled', time: '15 min ago' },
];

const rideAreaData = [
  { name: 'Mon', rides: 120 },
  { name: 'Tue', rides: 180 },
  { name: 'Wed', rides: 150 },
  { name: 'Thu', rides: 220 },
  { name: 'Fri', rides: 280 },
  { name: 'Sat', rides: 320 },
  { name: 'Sun', rides: 290 },
];

const cityData = [
  { name: 'Mumbai', rides: 45 },
  { name: 'Delhi', rides: 25 },
  { name: 'Bangalore', rides: 15 },
  { name: 'Chennai', rides: 10 },
  { name: 'Others', rides: 5 },
];

const COLORS = ['#22c55e', '#3b82f6', '#f59e0b', '#ef4444', '#8b5cf6'];

const AdminDashboard: React.FC = () => {
  return (
    <div className="min-h-screen bg-admin-bg">
      {/* Header */}
      <header className="bg-white border-b border-admin-border shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <div className="w-8 h-8 bg-brand-500 rounded-lg flex items-center justify-center">
                  <TruckIcon className="w-5 h-5 text-white" />
                </div>
              </div>
              <h1 className="ml-3 text-xl font-bold text-admin-text-primary">
                AutoWala Admin
              </h1>
            </div>

            <div className="flex items-center space-x-4">
              <div className="text-right">
                <p className="text-sm font-medium text-admin-text-primary">Admin User</p>
                <p className="text-xs text-admin-text-secondary">admin@autowala.com</p>
              </div>
              <div className="w-8 h-8 bg-brand-100 rounded-full flex items-center justify-center">
                <span className="text-sm font-medium text-brand-700">A</span>
              </div>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <StatCard
            title="Total Users"
            value={dashboardStats.totalUsers.toLocaleString()}
            growth={dashboardStats.userGrowth}
            icon={<UsersIcon className="w-8 h-8 text-blue-600" />}
            color="blue"
          />
          <StatCard
            title="Active Riders"
            value={dashboardStats.activeRiders.toLocaleString()}
            growth={dashboardStats.riderGrowth}
            icon={<TruckIcon className="w-8 h-8 text-green-600" />}
            color="green"
          />
          <StatCard
            title="Today's Rides"
            value={dashboardStats.todayRides.toLocaleString()}
            growth={dashboardStats.rideGrowth}
            icon={<MapPinIcon className="w-8 h-8 text-orange-600" />}
            color="orange"
          />
          <StatCard
            title="Total Revenue"
            value={`₹${(dashboardStats.totalRevenue / 100000).toFixed(1)}L`}
            growth={dashboardStats.revenueGrowth}
            icon={<CurrencyRupeeIcon className="w-8 h-8 text-purple-600" />}
            color="purple"
          />
        </div>

        {/* Charts Section */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
          {/* Rides Chart */}
          <div className="bg-white rounded-lg border border-admin-border shadow-card p-6">
            <h3 className="text-lg font-semibold text-admin-text-primary mb-4">
              Weekly Rides Overview
            </h3>
            <ResponsiveContainer width="100%" height={300}>
              <AreaChart data={rideAreaData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                <XAxis
                  dataKey="name"
                  axisLine={false}
                  tickLine={false}
                  tick={{ fontSize: 12, fill: '#64748b' }}
                />
                <YAxis
                  axisLine={false}
                  tickLine={false}
                  tick={{ fontSize: 12, fill: '#64748b' }}
                />
                <Tooltip
                  contentStyle={{
                    backgroundColor: 'white',
                    borderRadius: '8px',
                    border: '1px solid #e2e8f0',
                    boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)',
                  }}
                />
                <Area
                  type="monotone"
                  dataKey="rides"
                  stroke="#22c55e"
                  fill="#22c55e"
                  fillOpacity={0.1}
                  strokeWidth={2}
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>

          {/* City Distribution */}
          <div className="bg-white rounded-lg border border-admin-border shadow-card p-6">
            <h3 className="text-lg font-semibold text-admin-text-primary mb-4">
              Rides by City
            </h3>
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={cityData}
                  cx="50%"
                  cy="50%"
                  outerRadius={100}
                  fill="#8884d8"
                  dataKey="rides"
                  label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                >
                  {cityData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Recent Rides Table */}
        <div className="bg-white rounded-lg border border-admin-border shadow-card">
          <div className="px-6 py-4 border-b border-admin-border">
            <h3 className="text-lg font-semibold text-admin-text-primary">
              Recent Rides
            </h3>
          </div>
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-admin-border">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-admin-text-secondary uppercase tracking-wider">
                    User
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-admin-text-secondary uppercase tracking-wider">
                    Rider
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-admin-text-secondary uppercase tracking-wider">
                    Amount
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-admin-text-secondary uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-admin-text-secondary uppercase tracking-wider">
                    Time
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-admin-border">
                {recentRides.map((ride) => (
                  <tr key={ride.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-admin-text-primary">
                      {ride.user}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-admin-text-secondary">
                      {ride.rider}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-admin-text-primary font-medium">
                      ₹{ride.amount}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <StatusBadge status={ride.status} />
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-admin-text-secondary">
                      {ride.time}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </main>
    </div>
  );
};

// Stat Card Component
interface StatCardProps {
  title: string;
  value: string;
  growth: number;
  icon: React.ReactNode;
  color: 'blue' | 'green' | 'orange' | 'purple';
}

const StatCard: React.FC<StatCardProps> = ({ title, value, growth, icon, color }) => {
  const colorClasses = {
    blue: 'text-blue-600 bg-blue-50',
    green: 'text-green-600 bg-green-50',
    orange: 'text-orange-600 bg-orange-50',
    purple: 'text-purple-600 bg-purple-50',
  };

  return (
    <div className="bg-white rounded-lg border border-admin-border shadow-card p-6 hover:shadow-card-hover transition-shadow">
      <div className="flex items-center">
        <div className={`p-3 rounded-lg ${colorClasses[color]}`}>
          {icon}
        </div>
        <div className="ml-4 flex-1">
          <p className="text-sm font-medium text-admin-text-secondary">{title}</p>
          <p className="text-2xl font-bold text-admin-text-primary">{value}</p>
        </div>
      </div>
      <div className="mt-4 flex items-center">
        <div className={`flex items-center ${growth > 0 ? 'text-green-600' : 'text-red-600'}`}>
          <span className="text-sm font-medium">
            {growth > 0 ? '+' : ''}{growth}%
          </span>
        </div>
        <span className="text-sm text-admin-text-muted ml-1">vs last month</span>
      </div>
    </div>
  );
};

// Status Badge Component
interface StatusBadgeProps {
  status: string;
}

const StatusBadge: React.FC<StatusBadgeProps> = ({ status }) => {
  const getStatusConfig = (status: string) => {
    switch (status) {
      case 'completed':
        return {
          icon: <CheckCircleIcon className="w-4 h-4" />,
          text: 'Completed',
          classes: 'bg-green-100 text-green-800',
        };
      case 'in_progress':
        return {
          icon: <ClockIcon className="w-4 h-4" />,
          text: 'In Progress',
          classes: 'bg-blue-100 text-blue-800',
        };
      case 'cancelled':
        return {
          icon: <ExclamationTriangleIcon className="w-4 h-4" />,
          text: 'Cancelled',
          classes: 'bg-red-100 text-red-800',
        };
      default:
        return {
          icon: null,
          text: status,
          classes: 'bg-gray-100 text-gray-800',
        };
    }
  };

  const config = getStatusConfig(status);

  return (
    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${config.classes}`}>
      {config.icon && <span className="mr-1">{config.icon}</span>}
      {config.text}
    </span>
  );
};

export default AdminDashboard;