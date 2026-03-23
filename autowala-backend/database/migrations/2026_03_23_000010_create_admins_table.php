<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('admins', function (Blueprint $table) {
            $table->bigIncrements('id');

            // Profile
            $table->string('full_name', 255);
            $table->string('email', 255)->unique();
            $table->string('phone_number', 20)->nullable();

            // Authentication
            $table->string('password_hash', 255);

            // Permissions
            $table->enum('role', ['super_admin', 'kyc_reviewer', 'support', 'analyst']);
            $table->json('permissions')->nullable(); // Granular permissions

            // Account
            $table->boolean('is_active')->default(true);
            $table->timestamp('last_login_at')->nullable();

            // Timestamps
            $table->timestamps();

            // Indexes
            $table->index('email');
            $table->index('role');
            $table->index(['is_active', 'role']);
        });

        // Apply auto-update timestamp trigger
        DB::statement('
            CREATE TRIGGER update_admins_updated_at
            BEFORE UPDATE ON admins
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column()
        ');

        // Now add the foreign key constraint to documents table
        Schema::table('documents', function (Blueprint $table) {
            $table->foreign('verified_by_admin_id')->references('id')->on('admins')->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Remove foreign key from documents table first
        Schema::table('documents', function (Blueprint $table) {
            $table->dropForeign(['verified_by_admin_id']);
        });

        // Drop trigger
        DB::statement('DROP TRIGGER IF EXISTS update_admins_updated_at ON admins');

        Schema::dropIfExists('admins');
    }
};