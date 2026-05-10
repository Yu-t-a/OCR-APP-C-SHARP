using Microsoft.EntityFrameworkCore;
using Typhoon.Core.Data.Entities;

namespace Typhoon.Core.Data;

public class OcrDbContext : DbContext
{
    public OcrDbContext(DbContextOptions<OcrDbContext> options) : base(options) { }

    public DbSet<DocumentType> DocumentTypes { get; set; }
    public DbSet<OcrFile> OcrFiles { get; set; }
    public DbSet<OcrJob> OcrJobs { get; set; }
    public DbSet<OcrDocument> OcrDocuments { get; set; }
    public DbSet<OcrDocumentField> OcrDocumentFields { get; set; }
    public DbSet<OcrErrorLog> OcrErrorLogs { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<DocumentType>(e =>
        {
            e.ToTable("DocumentTypes");
            e.HasKey(x => x.Id);
            e.Property(x => x.TypeCode).HasMaxLength(50).IsRequired();
            e.Property(x => x.TypeName).HasMaxLength(100).IsRequired();
            e.HasIndex(x => x.TypeCode).IsUnique();
        });

        modelBuilder.Entity<OcrFile>(e =>
        {
            e.ToTable("OcrFiles");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasDefaultValueSql("NEWSEQUENTIALID()");
            e.Property(x => x.OriginalFileName).HasMaxLength(500).IsRequired();
            e.Property(x => x.StoredFilePath).HasMaxLength(1000).IsRequired();
            e.Property(x => x.MimeType).HasMaxLength(100);
            e.Property(x => x.UploadedAt).HasDefaultValueSql("GETUTCDATE()");
        });

        modelBuilder.Entity<OcrJob>(e =>
        {
            e.ToTable("OcrJobs");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasDefaultValueSql("NEWSEQUENTIALID()");
            e.Property(x => x.SourceFileName).HasMaxLength(500).IsRequired();
            e.Property(x => x.SourceFilePath).HasMaxLength(1000);
            e.Property(x => x.Status).HasMaxLength(20).HasDefaultValue("Pending");
            e.Property(x => x.CreatedAt).HasDefaultValueSql("GETUTCDATE()");

            e.HasOne(x => x.File)
             .WithMany(x => x.OcrJobs)
             .HasForeignKey(x => x.FileId)
             .OnDelete(DeleteBehavior.SetNull);

            e.HasOne(x => x.DocumentType)
             .WithMany(x => x.OcrJobs)
             .HasForeignKey(x => x.DocumentTypeId)
             .OnDelete(DeleteBehavior.SetNull);
        });

        modelBuilder.Entity<OcrDocument>(e =>
        {
            e.ToTable("OcrDocuments");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasDefaultValueSql("NEWSEQUENTIALID()");
            e.Property(x => x.PageNumber).HasDefaultValue(1);
            e.Property(x => x.IsVerified).HasDefaultValue(false);
            e.Property(x => x.CreatedAt).HasDefaultValueSql("GETUTCDATE()");
            e.Property(x => x.CreatedBy).HasMaxLength(100);

            e.HasOne(x => x.Job)
             .WithMany(x => x.OcrDocuments)
             .HasForeignKey(x => x.JobId)
             .OnDelete(DeleteBehavior.Cascade);

            e.HasOne(x => x.DocumentType)
             .WithMany(x => x.OcrDocuments)
             .HasForeignKey(x => x.DocumentTypeId)
             .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<OcrDocumentField>(e =>
        {
            e.ToTable("OcrDocumentFields");
            e.HasKey(x => x.Id);
            e.Property(x => x.FieldName).HasMaxLength(100).IsRequired();
            e.Property(x => x.FieldType).HasMaxLength(20);

            e.HasOne(x => x.Document)
             .WithMany(x => x.Fields)
             .HasForeignKey(x => x.DocumentId)
             .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<OcrErrorLog>(e =>
        {
            e.ToTable("OcrErrorLogs");
            e.HasKey(x => x.Id);
            e.Property(x => x.ErrorCode).HasMaxLength(50);
            e.Property(x => x.ErrorMessage).IsRequired();
            e.Property(x => x.CreatedAt).HasDefaultValueSql("GETUTCDATE()");

            e.HasOne(x => x.Job)
             .WithMany(x => x.OcrErrorLogs)
             .HasForeignKey(x => x.JobId)
             .OnDelete(DeleteBehavior.SetNull);
        });
    }
}
