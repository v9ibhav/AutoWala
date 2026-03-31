<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Facades\Hash;
use Carbon\Carbon;

class Admin extends Authenticatable
{
    use HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'full_name',
        'email',
        'phone_number',
        'password_hash',
        'role',
        'permissions',
        'is_active',
        'last_login_at',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password_hash',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'permissions' => 'array',
            'is_active' => 'boolean',
            'last_login_at' => 'datetime',
            'email_verified_at' => 'datetime',
            'password_hash' => 'hashed',
        ];
    }

    /**
     * Admin roles
     */
    const ROLE_SUPER_ADMIN = 'super_admin';
    const ROLE_KYC_REVIEWER = 'kyc_reviewer';
    const ROLE_SUPPORT = 'support';
    const ROLE_ANALYST = 'analyst';

    /**
     * Get all available roles
     */
    public static function getRoles(): array
    {
        return [
            self::ROLE_SUPER_ADMIN,
            self::ROLE_KYC_REVIEWER,
            self::ROLE_SUPPORT,
            self::ROLE_ANALYST,
        ];
    }

    /**
     * Default permissions for each role
     */
    public static function getDefaultPermissions(string $role): array
    {
        switch ($role) {
            case self::ROLE_SUPER_ADMIN:
                return [
                    'manage_admins',
                    'manage_users',
                    'manage_riders',
                    'review_kyc',
                    'handle_complaints',
                    'view_analytics',
                    'manage_system_settings',
                ];

            case self::ROLE_KYC_REVIEWER:
                return [
                    'review_kyc',
                    'view_rider_documents',
                    'approve_reject_riders',
                ];

            case self::ROLE_SUPPORT:
                return [
                    'handle_complaints',
                    'view_users',
                    'view_riders',
                    'send_notifications',
                ];

            case self::ROLE_ANALYST:
                return [
                    'view_analytics',
                    'export_reports',
                    'view_ride_data',
                ];

            default:
                return [];
        }
    }

    /**
     * Get the password attribute (Laravel Auth compatibility)
     */
    public function getAuthPassword()
    {
        return $this->password_hash;
    }

    /**
     * Set the password hash
     */
    public function setPasswordAttribute($value)
    {
        $this->attributes['password_hash'] = Hash::make($value);
    }

    /**
     * Get the documents verified by this admin
     */
    public function verifiedDocuments()
    {
        return $this->hasMany(Document::class, 'verified_by_admin_id');
    }

    /**
     * Get notifications sent by this admin
     */
    public function sentNotifications()
    {
        return $this->hasMany(Notification::class, 'sent_by_admin_id');
    }

    /**
     * Check if admin has a specific permission
     */
    public function hasPermission(string $permission): bool
    {
        $permissions = $this->permissions ?? [];
        return in_array($permission, $permissions);
    }

    /**
     * Check if admin has any of the given permissions
     */
    public function hasAnyPermission(array $permissions): bool
    {
        $adminPermissions = $this->permissions ?? [];
        return !empty(array_intersect($permissions, $adminPermissions));
    }

    /**
     * Check if admin has all of the given permissions
     */
    public function hasAllPermissions(array $permissions): bool
    {
        $adminPermissions = $this->permissions ?? [];
        return empty(array_diff($permissions, $adminPermissions));
    }

    /**
     * Add permission to admin
     */
    public function addPermission(string $permission): bool
    {
        $permissions = $this->permissions ?? [];

        if (!in_array($permission, $permissions)) {
            $permissions[] = $permission;
            return $this->update(['permissions' => $permissions]);
        }

        return true;
    }

    /**
     * Remove permission from admin
     */
    public function removePermission(string $permission): bool
    {
        $permissions = $this->permissions ?? [];
        $updatedPermissions = array_values(array_filter($permissions, fn($p) => $p !== $permission));

        return $this->update(['permissions' => $updatedPermissions]);
    }

    /**
     * Set permissions for admin
     */
    public function setPermissions(array $permissions): bool
    {
        return $this->update(['permissions' => array_values(array_unique($permissions))]);
    }

    /**
     * Reset permissions to role defaults
     */
    public function resetToDefaultPermissions(): bool
    {
        $defaultPermissions = self::getDefaultPermissions($this->role);
        return $this->setPermissions($defaultPermissions);
    }

    /**
     * Record login time
     */
    public function recordLogin(): bool
    {
        return $this->update(['last_login_at' => now()]);
    }

    /**
     * Check if admin is super admin
     */
    public function isSuperAdmin(): bool
    {
        return $this->role === self::ROLE_SUPER_ADMIN;
    }

    /**
     * Check if admin can manage other admins
     */
    public function canManageAdmins(): bool
    {
        return $this->isSuperAdmin() || $this->hasPermission('manage_admins');
    }

    /**
     * Check if admin can review KYC
     */
    public function canReviewKYC(): bool
    {
        return $this->hasPermission('review_kyc');
    }

    /**
     * Check if admin can handle complaints
     */
    public function canHandleComplaints(): bool
    {
        return $this->hasPermission('handle_complaints');
    }

    /**
     * Check if admin can view analytics
     */
    public function canViewAnalytics(): bool
    {
        return $this->hasPermission('view_analytics');
    }

    /**
     * Get full display name
     */
    public function getDisplayNameAttribute(): string
    {
        return $this->full_name;
    }

    /**
     * Get role display name
     */
    public function getRoleDisplayNameAttribute(): string
    {
        return match ($this->role) {
            self::ROLE_SUPER_ADMIN => 'Super Admin',
            self::ROLE_KYC_REVIEWER => 'KYC Reviewer',
            self::ROLE_SUPPORT => 'Support Agent',
            self::ROLE_ANALYST => 'Data Analyst',
            default => ucfirst(str_replace('_', ' ', $this->role)),
        };
    }

    /**
     * Scope for active admins
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    /**
     * Scope for inactive admins
     */
    public function scopeInactive($query)
    {
        return $query->where('is_active', false);
    }

    /**
     * Scope for specific role
     */
    public function scopeWithRole($query, string $role)
    {
        return $query->where('role', $role);
    }

    /**
     * Scope for admins with specific permission
     */
    public function scopeWithPermission($query, string $permission)
    {
        return $query->whereJsonContains('permissions', $permission);
    }

    /**
     * Scope for recently logged in admins
     */
    public function scopeRecentlyActive($query, int $days = 30)
    {
        return $query->where('last_login_at', '>=', now()->subDays($days));
    }

    /**
     * Create a new admin with default permissions
     */
    public static function createWithDefaults(array $data): self
    {
        $role = $data['role'] ?? self::ROLE_SUPPORT;
        $defaultPermissions = self::getDefaultPermissions($role);

        return self::create(array_merge($data, [
            'permissions' => $defaultPermissions,
            'is_active' => true,
        ]));
    }
}