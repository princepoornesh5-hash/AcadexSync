"""
ACADEXSYNC - Complete Project Report Generator
Constructs a publication-grade, professionally formatted DOCX and PDF academic project report.
Follows all academic formatting rules from SV Government Polytechnic & SBTET AP.
"""
import os
import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import qn, nsdecls

DIAGRAMS_DIR = "ACADEXSYNC_Diagrams"
DOCS_DIR = "docs/runtime_qa"

def set_cell_background(cell, fill_hex):
    tcPr = cell._tc.get_or_add_tcPr()
    tcPr.append(parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill_hex}"/>'))

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = OxmlElement('w:tcMar')
    for m, val in [('top', top), ('bottom', bottom), ('left', left), ('right', right)]:
        node = OxmlElement(f'w:{m}')
        node.set(qn('w:w'), str(val))
        node.set(qn('w:type'), 'dxa')
        tcMar.append(node)
    tcPr.append(tcMar)

def set_cell_borders(cell, top="CCCCCC", bottom="CCCCCC", left="none", right="none", sz="4"):
    tcPr = cell._tc.get_or_add_tcPr()
    tcBorders = OxmlElement('w:tcBorders')
    for b_name, b_val in [('top', top), ('bottom', bottom), ('left', left), ('right', right)]:
        b_elm = OxmlElement(f'w:{b_name}')
        if b_val == "none":
            b_elm.set(qn('w:val'), 'none')
        else:
            b_elm.set(qn('w:val'), 'single')
            b_elm.set(qn('w:sz'), sz)
            b_elm.set(qn('w:space'), '0')
            b_elm.set(qn('w:color'), b_val)
        tcBorders.append(b_elm)
    tcPr.append(tcBorders)

class AcadexDocBuilder:
    def __init__(self):
        self.doc = docx.Document()
        self.setup_page_geometry()
        self.setup_styles()
        self.figure_count = 0
        self.table_count = 0
        self.listing_count = 0

    def setup_page_geometry(self):
        section = self.doc.sections[0]
        section.page_width = Inches(8.27)    # A4 Width
        section.page_height = Inches(11.69)  # A4 Height
        # Margins per WhatsApp specification:
        section.left_margin = Inches(1.5)    # 1.5 inches for book binding
        section.top_margin = Inches(1.0)     # 1.0 inch
        section.bottom_margin = Inches(1.0)  # 1.0 inch
        section.right_margin = Inches(1.0)   # 1.0 inch

        # Setup Header & Footer
        header = section.header
        hp = header.paragraphs[0]
        hp.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        hrun = hp.add_run("ACADEXSYNC | Multi-Tenant Campus Management System")
        hrun.font.name = "Times New Roman"
        hrun.font.size = Pt(8.5)
        hrun.font.color.rgb = RGBColor(0x64, 0x74, 0x8B)

        footer = section.footer
        fp = footer.paragraphs[0]
        fp.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
        frun = fp.add_run("ACADEXSYNC | Project Report | SV Government Polytechnic")
        frun.font.name = "Times New Roman"
        frun.font.size = Pt(8.5)
        frun.font.color.rgb = RGBColor(0x64, 0x74, 0x8B)

    def setup_styles(self):
        normal_style = self.doc.styles['Normal']
        normal_style.font.name = 'Times New Roman'
        normal_style.font.size = Pt(12)
        normal_style.font.color.rgb = RGBColor(0x0F, 0x17, 0x2A)

    def add_chapter_heading(self, title):
        p = self.doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.LEFT
        p.paragraph_format.space_before = Pt(16)
        p.paragraph_format.space_after = Pt(10)
        p.paragraph_format.keep_with_next = True
        run = p.add_run(title.upper())
        run.font.name = 'Times New Roman'
        run.font.size = Pt(16)
        run.font.bold = True
        run.font.color.rgb = RGBColor(0x1E, 0x3A, 0x8A) # Deep Navy
        return p

    def add_section_heading(self, title):
        p = self.doc.add_paragraph()
        p.paragraph_format.space_before = Pt(12)
        p.paragraph_format.space_after = Pt(6)
        p.paragraph_format.keep_with_next = True
        run = p.add_run(title)
        run.font.name = 'Times New Roman'
        run.font.size = Pt(14)
        run.font.bold = True
        run.font.color.rgb = RGBColor(0x1E, 0x29, 0x3B)
        return p

    def add_subheading(self, title):
        p = self.doc.add_paragraph()
        p.paragraph_format.space_before = Pt(10)
        p.paragraph_format.space_after = Pt(4)
        p.paragraph_format.keep_with_next = True
        run = p.add_run(title)
        run.font.name = 'Times New Roman'
        run.font.size = Pt(12.5)
        run.font.bold = True
        run.font.color.rgb = RGBColor(0x33, 0x41, 0x55)
        return p

    def add_body_paragraph(self, text):
        p = self.doc.add_paragraph()
        p.paragraph_format.line_spacing = 1.5
        p.paragraph_format.space_after = Pt(6)
        p.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
        run = p.add_run(text)
        run.font.name = 'Times New Roman'
        run.font.size = Pt(12)
        run.font.color.rgb = RGBColor(0x0F, 0x17, 0x2A)
        return p

    def add_bullet_point(self, title, desc):
        p = self.doc.add_paragraph(style='List Bullet')
        p.paragraph_format.line_spacing = 1.5
        p.paragraph_format.space_after = Pt(4)
        p.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
        run_t = p.add_run(title + ": ")
        run_t.font.name = 'Times New Roman'
        run_t.font.size = Pt(12)
        run_t.font.bold = True
        run_t.font.color.rgb = RGBColor(0x1E, 0x3A, 0x8A)

        run_d = p.add_run(desc)
        run_d.font.name = 'Times New Roman'
        run_d.font.size = Pt(12)
        run_d.font.color.rgb = RGBColor(0x0F, 0x17, 0x2A)
        return p

    def add_page_break(self):
        self.doc.add_page_break()

    def add_figure(self, image_path, caption, width_inches=5.6):
        if not os.path.exists(image_path):
            print(f"Warning: Image path not found: {image_path}")
            return None
        self.figure_count += 1
        p_img = self.doc.add_paragraph()
        p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p_img.paragraph_format.space_before = Pt(8)
        p_img.paragraph_format.space_after = Pt(4)
        run_img = p_img.add_run()
        run_img.add_picture(image_path, width=Inches(width_inches))

        p_cap = self.doc.add_paragraph()
        p_cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p_cap.paragraph_format.space_after = Pt(10)
        p_cap.paragraph_format.keep_with_next = True
        run_cap = p_cap.add_run(f"Figure {self.figure_count}: {caption}")
        run_cap.font.name = 'Times New Roman'
        run_cap.font.size = Pt(10)
        run_cap.font.italic = True
        run_cap.font.bold = True
        run_cap.font.color.rgb = RGBColor(0x33, 0x41, 0x55)
        return p_img

    def add_code_listing(self, title, file_path, code_text, explanation_blocks, inputs="", outputs="", security=""):
        self.listing_count += 1
        p_h = self.doc.add_paragraph()
        p_h.paragraph_format.space_before = Pt(12)
        p_h.paragraph_format.space_after = Pt(3)
        p_h.paragraph_format.keep_with_next = True
        run_h = p_h.add_run(f"Listing {self.listing_count}: {title}")
        run_h.font.name = 'Times New Roman'
        run_h.font.size = Pt(11)
        run_h.font.bold = True
        run_h.font.color.rgb = RGBColor(0x1E, 0x3A, 0x8A)

        p_file = self.doc.add_paragraph()
        p_file.paragraph_format.space_after = Pt(4)
        run_f = p_file.add_run(f"File Path: {file_path}")
        run_f.font.name = 'Times New Roman'
        run_f.font.size = Pt(9.5)
        run_f.font.italic = True
        run_f.font.color.rgb = RGBColor(0x64, 0x74, 0x8B)

        # Code container table
        table = self.doc.add_table(rows=1, cols=1)
        table.alignment = WD_TABLE_ALIGNMENT.CENTER
        cell = table.cell(0, 0)
        set_cell_background(cell, "F8FAFC")
        set_cell_margins(cell, top=120, bottom=120, left=180, right=180)
        set_cell_borders(cell, top="CBD5E1", bottom="CBD5E1", left="2563EB", right="CBD5E1", sz="12")

        p_code = cell.paragraphs[0]
        p_code.paragraph_format.line_spacing = 1.15
        p_code.paragraph_format.space_before = Pt(0)
        p_code.paragraph_format.space_after = Pt(0)
        run_c = p_code.add_run(code_text.strip())
        run_c.font.name = 'Courier New'
        run_c.font.size = Pt(8.5)
        run_c.font.color.rgb = RGBColor(0x0F, 0x17, 0x2A)

        # Explanation
        p_exp_h = self.doc.add_paragraph()
        p_exp_h.paragraph_format.space_before = Pt(6)
        p_exp_h.paragraph_format.space_after = Pt(2)
        r_eh = p_exp_h.add_run("Technical Implementation & Execution Flow:")
        r_eh.font.name = 'Times New Roman'
        r_eh.font.size = Pt(10.5)
        r_eh.font.bold = True
        r_eh.font.color.rgb = RGBColor(0x1E, 0x29, 0x3B)

        for block_title, block_desc in explanation_blocks:
            self.add_bullet_point(block_title, block_desc)

        if inputs or outputs or security:
            p_io = self.doc.add_paragraph()
            p_io.paragraph_format.line_spacing = 1.3
            p_io.paragraph_format.space_after = Pt(8)
            if inputs:
                r1 = p_io.add_run("Inputs: ")
                r1.font.bold = True
                r1.font.size = Pt(10)
                p_io.add_run(inputs + "  ").font.size = Pt(10)
            if outputs:
                r2 = p_io.add_run("Outputs: ")
                r2.font.bold = True
                r2.font.size = Pt(10)
                p_io.add_run(outputs + "  ").font.size = Pt(10)
            if security:
                r3 = p_io.add_run("Security & Boundaries: ")
                r3.font.bold = True
                r3.font.size = Pt(10)
                p_io.add_run(security).font.size = Pt(10)

    def add_table_data(self, title, headers, rows, col_widths=None):
        self.table_count += 1
        p_cap = self.doc.add_paragraph()
        p_cap.paragraph_format.space_before = Pt(10)
        p_cap.paragraph_format.space_after = Pt(4)
        p_cap.paragraph_format.keep_with_next = True
        run_cap = p_cap.add_run(f"Table {self.table_count}: {title}")
        run_cap.font.name = 'Times New Roman'
        run_cap.font.size = Pt(10.5)
        run_cap.font.bold = True
        run_cap.font.color.rgb = RGBColor(0x1E, 0x3A, 0x8A)

        table = self.doc.add_table(rows=len(rows) + 1, cols=len(headers))
        table.alignment = WD_TABLE_ALIGNMENT.CENTER

        # Header Row
        hdr_cells = table.rows[0].cells
        for i, header_text in enumerate(headers):
            hdr_cells[i].text = header_text
            set_cell_background(hdr_cells[i], "1E3A8A") # Navy
            set_cell_margins(hdr_cells[i], top=120, bottom=120, left=140, right=140)
            set_cell_borders(hdr_cells[i], top="1E3A8A", bottom="1E3A8A", left="1E3A8A", right="1E3A8A")
            for p in hdr_cells[i].paragraphs:
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
                for r in p.runs:
                    r.font.name = 'Times New Roman'
                    r.font.size = Pt(10)
                    r.font.bold = True
                    r.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)

        # Body Rows
        for r_idx, row_data in enumerate(rows):
            row_cells = table.rows[r_idx + 1].cells
            bg_hex = "FFFFFF" if r_idx % 2 == 0 else "F8FAFC"
            for c_idx, cell_value in enumerate(row_data):
                row_cells[c_idx].text = str(cell_value)
                set_cell_background(row_cells[c_idx], bg_hex)
                set_cell_margins(row_cells[c_idx], top=90, bottom=90, left=130, right=130)
                set_cell_borders(row_cells[c_idx], top="E2E8F0", bottom="E2E8F0", left="E2E8F0", right="E2E8F0")
                for p in row_cells[c_idx].paragraphs:
                    p.paragraph_format.line_spacing = 1.15
                    for r in p.runs:
                        r.font.name = 'Times New Roman'
                        r.font.size = Pt(9.5)
                        r.font.color.rgb = RGBColor(0x0F, 0x17, 0x2A)

        if col_widths:
            for row in table.rows:
                for idx, width in enumerate(col_widths):
                    row.cells[idx].width = Inches(width)

        p_sp = self.doc.add_paragraph()
        p_sp.paragraph_format.space_after = Pt(6)

print("AcadexDocBuilder helper initialized.")

