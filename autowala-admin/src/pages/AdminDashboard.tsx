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

const COLORS = ['#F59E0B', '#D97706', '#B45309', '#16A34A', '#92400E'];

const AdminDashboard: React.FC = () => {
  return (
    <div className="min-h-screen bg-admin-bg">
      {/* Header */}
      <header className="bg-brand-500 border-b border-brand-600 shadow-lg">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <div className="w-10 h-10 bg-white rounded-lg flex items-center justify-center shadow-md">
                  <TruckIcon className="w-6 h-6 text-brand-600" />
                </div>
              </div>
              <h1 className="ml-3 text-xl font-bold text-white">
                AutoWala Admin
              </h1>
            </div>

            <div className="flex items-center space-x-4">
              <div className="text-right">
                <p className="text-sm font-medium text-white">Admin User</p>
                <p className="text-xs text-brand-100">admin@autowala.com</p>
              </div>
              <div className="w-8 h-8 bg-white rounded-full flex items-center justify-center">
                <span className="text-sm font-medium text-brand-600">A</span>
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
            icon={<UsersIcon className="w-8 h-8 text-brand-600" />}
            color="gold"
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
            icon={<MapPinIcon className="w-8 h-8 text-brand-500" />}
            color="amber"
          />
          <StatCard
            title="Total Revenue"
            value={`₹${(dashboardStats.totalRevenue / 100000).toFixed(1)}L`}
            growth={dashboardStats.revenueGrowth}
            icon={<CurrencyRupeeIcon className="w-8 h-8 text-brand-700" />}
            color="dark"
          />
        </div>

        {/* Charts Section */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
          {/* Rides Chart */}
          <div className="bg-white rounded-lg border border-brand-200 shadow-card p-6">
            <h3 className="text-lg font-semibold text-admin-text-primary mb-4">
              Weekly Rides Overview
            </h3>
            <ResponsiveContainer width="100%" height={300}>
              <AreaChart data={rideAreaData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#FDE68A" />
                <XAxis
                  dataKey="name"
                  axisLine={false}
                  tickLine={false}
                  tick={{ fontSize: 12, fill: '#78350F' }}
                />
                <YAxis
                  axisLine={false}
                  tickLine={false}
                  tick={{ fontSize: 12, fill: '#78350F' }}
                />
                <Tooltip
                  contentStyle={{
                    backgroundColor: 'white',
                    borderRadius: '8px',
                    border: '1px solid #FDE68A',
                    boxShadow: '0 4px 6px -1px rgba(245, 158, 11, 0.2)',
                  }}
                />
                <Area
                  type="monotone"
                  dataKey="rides"
                  stroke="#F59E0B"
                  fill="#F59E0B"
                  fillOpacity={0.2}
                  strokeWidth={2}
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>

          {/* City Distribution */}
          <div className="bg-white rounded-lg border border-brand-200 shadow-card p-6">
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
        <div className="bg-white rounded-lg border border-brand-200 shadow-card">
          <div className="px-6 py-4 border-b border-brand-200">
            <h3 className="text-lg font-semibold text-admin-text-primary">
              Recent Rides
            </h3>
          </div>
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-brand-200">
              <thead className="bg-brand-50">
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
              <tbody className="bg-white divide-y divide-brand-100">
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
  color: 'gold' | 'green' | 'amber' | 'dark';
}

const StatCard: React.FC<StatCardProps> = ({ title, value, growth, icon, color }) => {
  const colorClasses = {
    gold: 'text-brand-600 bg-brand-100',
    green: 'text-green-600 bg-green-50',
    amber: 'text-brand-500 bg-brand-50',
    dark: 'text-brand-700 bg-brand-200',
  };

  return (
    <div className="bg-white rounded-lg border border-brand-200 shadow-card p-6 hover:shadow-card-hover hover:border-brand-300 transition-all">
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
          classes: 'bg-brand-100 text-brand-800',
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
          classes: 'bg-brand-50 text-brand-700',
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