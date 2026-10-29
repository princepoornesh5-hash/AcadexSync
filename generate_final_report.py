"""
ACADEXSYNC - Master Assembler Script
Builds the complete publication-grade DOCX report and exports to PDF.
"""
import sys
import os
import time

from report_builder import AcadexDocBuilder
from report_preliminaries import generate_report_preliminaries
from report_chapters_1_to_5 import generate_chapters_1_to_5
from report_chapters_6_to_8 import generate_chapters_6_to_8
from report_chapter_9 import generate_chapter_9
from report_chapters_10_to_14 import generate_chapters_10_to_14

def main():
    print("==================================================================")
    print("STARTING ACADEXSYNC MASTER REPORT GENERATION")
    print("==================================================================")
    t0 = time.time()

    builder = AcadexDocBuilder()

    print("[1/5] Generating Preliminaries (Title, Certificate, Declaration, Acknowledgement, Abstract, TOC, Lists)...")
    generate_report_preliminaries(builder)

    print("[2/5] Generating Chapters 1 to 5 (Introduction, Project Description, Computational Env, Feasibility, System Analysis)...")
    generate_chapters_1_to_5(builder)

    print("[3/5] Generating Chapters 6 to 8 (Architecture, Role-Based Access, System Implementation)...")
    generate_chapters_6_to_8(builder)

    print("[4/5] Generating Chapter 9 (16 Verified Production Code Listings with Deep Technical Explanations)...")
    generate_chapter_9(builder)

    print("[5/5] Generating Chapters 10 to 14 & Appendices (UML Diagrams, Testing, Screenshots, Conclusions, Appendices)...")
    generate_chapters_10_to_14(builder)

    docx_output = "ACADEXSYNC_Complete_Project_Report.docx"
    print(f"Saving Master Word Document: {docx_output}...")
    builder.doc.save(docx_output)

    file_size_mb = os.path.getsize(docx_output) / (1024 * 1024)
    print(f"SUCCESS! {docx_output} generated successfully ({file_size_mb:.2f} MB) in {time.time() - t0:.1f}s.")

    # Check for PDF Export
    pdf_output = "ACADEXSYNC_Complete_Project_Report.pdf"
    print(f"Attempting PDF generation: {pdf_output}...")
    pdf_generated = False

    # Try Pages / CLI or reportlab
    try:
        import subprocess
        # Check if soffice or libreoffice exists
        soffice = subprocess.run(["which", "soffice"], capture_output=True, text=True).stdout.strip()
        if soffice:
            print(f"Converting via LibreOffice ({soffice})...")
            subprocess.run([soffice, "--headless", "--convert-to", "pdf", docx_output], check=True)
            pdf_generated = os.path.exists(pdf_output)
    except Exception as e:
        print(f"LibreOffice export skipped: {e}")

    if not pdf_generated:
        print("Note: Automated headless LibreOffice not installed on host. DOCX is the authoritative editable deliverable.")

    print("==================================================================")
    print("MASTER REPORT GENERATION COMPLETE")
    print("==================================================================")

if __name__ == "__main__":
    main()

