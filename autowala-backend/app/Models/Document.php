<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Carbon\Carbon;

class Document extends Model
{
    use HasFactory, SoftDeletes;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'rider_id',
        'document_type',
        'document_number',
        'document_url_front',
        'document_url_back',
        'document_url_additional',
        'is_verified',
        'verified_by_admin_id',
        'verified_at',
        'verification_notes',
        'expiry_date',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'is_verified' => 'boolean',
            'verified_at' => 'datetime',
            'expiry_date' => 'date',
            'uploaded_at' => 'datetime',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
            'deleted_at' => 'datetime',
        ];
    }

    /**
     * Document types
     */
    const TYPE_AADHAR = 'aadhar';
    const TYPE_LICENSE = 'license';
    const TYPE_REGISTRATION = 'registration';
    const TYPE_INSURANCE = 'insurance';
    const TYPE_BANK_ACCOUNT = 'bank_account';

    /**
     * Get the rider this document belongs to
     */
    public function rider()
    {
        return $this->belongsTo(Rider::class);
    }

    /**
     * Get the admin who verified this document
     */
    public function verifiedBy()
    {
        return $this->belongsTo(Admin::class, 'verified_by_admin_id');
    }

    /**
     * Check if document is expired
     */
    public function isExpired(): bool
    {
        return $this->expiry_date && $this->expiry_date->isPast();
    }

    /**
     * Check if document expires soon (within 30 days)
     */
    public function expiresSoon(): bool
    {
        return $this->expiry_date && $this->expiry_date->isBefore(now()->addDays(30));
    }

    /**
     * Verify the document
     */
    public function verify(int $adminId, ?string $notes = null): bool
    {
        return $this->update([
            'is_verified' => true,
            'verified_by_admin_id' => $adminId,
            'verified_at' => now(),
            'verification_notes' => $notes,
        ]);
    }

    /**
     * Reject the document
     */
    public function reject(int $adminId, string $notes): bool
    {
        return $this->update([
            'is_verified' => false,
            'verified_by_admin_id' => $adminId,
            'verified_at' => now(),
            'verification_notes' => $notes,
        ]);
    }

    /**
     * Get display name for document type
     */
    public function getDocumentTypeDisplayAttribute(): string
    {
        $types = [
            self::TYPE_AADHAR => 'Aadhar Card',
            self::TYPE_LICENSE => 'Driving License',
            self::TYPE_REGISTRATION => 'Vehicle Registration',
            self::TYPE_INSURANCE => 'Vehicle Insurance',
            self::TYPE_BANK_ACCOUNT => 'Bank Account Proof',
        ];

        return $types[$this->document_type] ?? ucfirst($this->document_type);
    }

    /**
     * Scope for verified documents
     */
    public function scopeVerified($query)
    {
        return $query->where('is_verified', true);
    }

    /**
     * Scope for pending documents
     */
    public function scopePending($query)
    {
        return $query->where('is_verified', false)->whereNull('verified_at');
    }

    /**
     * Scope for expired documents
     */
    public function scopeExpired($query)
    {
        return $query->whereNotNull('expiry_date')
            ->whereDate('expiry_date', '<', now());
    }

    /**
     * Scope for documents expiring soon
     */
    public function scopeExpiringSoon($query, int $days = 30)
    {
        return $query->whereNotNull('expiry_date')
            ->whereDate('expiry_date', '<=', now()->addDays($days))
            ->whereDate('expiry_date', '>=', now());
    }
}