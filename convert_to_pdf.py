"""
ACADEXSYNC - DOCX to PDF Renderer via ReportLab
Reads ACADEXSYNC_Complete_Project_Report.docx and outputs a high-fidelity print-ready PDF.
"""
import os
import sys
import docx
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image, PageBreak, KeepTogether
)
from reportlab.pdfgen import canvas

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super().showPage()
        super().save()

    def draw_page_decorations(self, page_count):
        self.saveState()
        self.setFont("Times-Roman", 8.5)
        self.setFillColor(colors.HexColor("#64748B"))

        # Do not draw headers/footers on title page (page 1)
        if self._pageNumber > 1:
            # Header
            self.drawRightString(A4[0] - 72, A4[1] - 45, "ACADEXSYNC | Multi-Tenant Campus Management System")
            self.setStrokeColor(colors.HexColor("#CBD5E1"))
            self.setLineWidth(0.5)
            self.line(108, A4[1] - 52, A4[0] - 72, A4[1] - 52)

            # Footer
            self.drawString(108, 45, "ACADEXSYNC | Project Report | SV Government Polytechnic")
            page_text = f"Page {self._pageNumber} of {page_count}"
            self.drawRightString(A4[0] - 72, 45, page_text)
            self.line(108, 58, A4[0] - 72, 58)

        self.restoreState()

def build_pdf_from_docx(docx_path, pdf_path):
    print(f"Reading {docx_path}...")
    doc = docx.Document(docx_path)

    # A4 Dimensions in points: 595.27 x 841.89
    # Left margin: 1.5 in = 108 pt
    # Top margin: 1.0 in = 72 pt
    # Bottom margin: 1.0 in = 72 pt
    # Right margin: 1.0 in = 72 pt
    # Printable width: 595.27 - 108 - 72 = 415.27 pt (approx 5.77 in)
    pdf_doc = SimpleDocTemplate(
        pdf_path,
        pagesize=A4,
        leftMargin=108,
        rightMargin=72,
        topMargin=72,
        bottomMargin=72
    )

    styles = getSampleStyleSheet()

    body_style = ParagraphStyle(
        'AcadexBody',
        parent=styles['Normal'],
        fontName='Times-Roman',
        fontSize=11,
        leading=16,
        textColor=colors.HexColor('#0F172A'),
        alignment=4, # Justified
        spaceAfter=6
    )

    title_style = ParagraphStyle(
        'AcadexTitle',
        parent=styles['Normal'],
        fontName='Times-Bold',
        fontSize=18,
        leading=22,
        textColor=colors.HexColor('#1E3A8A'),
        alignment=1, # Center
        spaceAfter=12
    )

    h1_style = ParagraphStyle(
        'AcadexH1',
        parent=styles['Normal'],
        fontName='Times-Bold',
        fontSize=14,
        leading=18,
        textColor=colors.HexColor('#1E3A8A'),
        spaceBefore=14,
        spaceAfter=8,
        keepWithNext=True
    )

    h2_style = ParagraphStyle(
        'AcadexH2',
        parent=styles['Normal'],
        fontName='Times-Bold',
        fontSize=12,
        leading=16,
        textColor=colors.HexColor('#1E293B'),
        spaceBefore=10,
        spaceAfter=6,
        keepWithNext=True
    )

    caption_style = ParagraphStyle(
        'AcadexCaption',
        parent=styles['Normal'],
        fontName='Times-Italic',
        fontSize=9.5,
        leading=13,
        textColor=colors.HexColor('#334155'),
        alignment=1, # Center
        spaceBefore=4,
        spaceAfter=8,
        keepWithNext=True
    )

    code_style = ParagraphStyle(
        'AcadexCode',
        parent=styles['Normal'],
        fontName='Courier',
        fontSize=7.5,
        leading=9.5,
        textColor=colors.HexColor('#0F172A'),
        spaceBefore=0,
        spaceAfter=0
    )

    story = []

    # Map docx elements
    # In docx, body contains paragraphs and tables in order of document.element.body
    body_elements = doc._body._element

    print("Parsing docx elements...")
    for child in body_elements:
        tag = child.tag.split('}')[-1]

        if tag == 'p':
            p_elm = child
            p_obj = docx.text.paragraph.Paragraph(p_elm, doc)
            text = p_obj.text.strip()

            if not text:
                # Check if paragraph has images
                blips = p_elm.xpath('.//a:blip/@r:embed')
                if blips:
                    for rel_id in blips:
                        rel = doc.part.rels[rel_id]
                        img_part = rel.target_ref
                        # Extract image bytes or file
                        img_path = os.path.join(os.path.dirname(docx_path), img_part)
                        # Or read image part directly
                        try:
                            blob = rel.target_part.blob
                            tmp_img = f"/tmp/rel_{rel_id}.png"
                            with open(tmp_img, "wb") as f_img:
                                f_img.write(blob)
                            # Add image flowable (max width: 415 pt)
                            img_f = Image(tmp_img, width=400, height=240)
                            story.append(img_f)
                        except Exception as e:
                            pass
                continue

            # Detect style by font size and formatting
            runs = p_obj.runs
            is_bold = any(r.bold for r in runs)
            font_size = runs[0].font.size.pt if runs and runs[0].font.size else 12

            # Clean XML entities
            clean_text = text.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')

            if "ACADEXSYNC" in text and font_size >= 18:
                story.append(Paragraph(clean_text, title_style))
            elif text.startswith("CHAPTER") or (is_bold and font_size >= 15):
                story.append(Spacer(1, 10))
                story.append(Paragraph(clean_text, h1_style))
            elif is_bold and font_size >= 13:
                story.append(Paragraph(clean_text, h2_style))
            elif text.startswith("Figure ") or text.startswith("Table ") or text.startswith("Listing "):
                story.append(Paragraph(f"<b>{clean_text}</b>", caption_style))
            elif text.startswith("• ") or text.startswith("1. ") or text.startswith("2. "):
                story.append(Paragraph(clean_text, body_style))
            else:
                story.append(Paragraph(clean_text, body_style))

            # Check if paragraph has page break
            if 'w:br' in p_elm.xml and 'type="page"' in p_elm.xml:
                story.append(PageBreak())

        elif tag == 'tbl':
            tbl_elm = child
            tbl_obj = docx.table.Table(tbl_elm, doc)
            data = []
            for row in tbl_obj.rows:
                row_data = []
                for cell in row.cells:
                    # Clean text
                    ct = cell.text.strip().replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
                    if len(tbl_obj.rows) == 1 and len(row.cells) == 1:
                        # Code snippet box
                        ct_para = Paragraph(ct.replace('\n', '<br/>'), code_style)
                    else:
                        ct_para = Paragraph(ct.replace('\n', '<br/>'), ParagraphStyle('CellP', parent=body_style, fontSize=8.5, leading=11))
                    row_data.append(ct_para)
                data.append(row_data)

            if data:
                # Wrap in ReportLab table
                col_count = len(data[0])
                available_w = 415.0
                col_w = [available_w / col_count] * col_count

                rl_tbl = Table(data, colWidths=col_w)
                if len(data) > 1 and len(data[0]) > 1:
                    rl_tbl.setStyle(TableStyle([
                        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1E3A8A')),
                        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
                        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
                        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
                        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
                        ('TOPPADDING', (0, 0), (-1, -1), 4),
                        ('LEFTPADDING', (0, 0), (-1, -1), 5),
                        ('RIGHTPADDING', (0, 0), (-1, -1), 5),
                        ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#CBD5E1')),
                    ]))
                else:
                    # Single cell code block
                    rl_tbl.setStyle(TableStyle([
                        ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor('#F8FAFC')),
                        ('LINELEFT', (0, 0), (-1, -1), 2.5, colors.HexColor('#2563EB')),
                        ('BOX', (0, 0), (-1, -1), 0.5, colors.HexColor('#CBD5E1')),
                        ('TOPPADDING', (0, 0), (-1, -1), 6),
                        ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
                        ('LEFTPADDING', (0, 0), (-1, -1), 8),
                        ('RIGHTPADDING', (0, 0), (-1, -1), 8),
                    ]))

                story.append(Spacer(1, 4))
                story.append(rl_tbl)
                story.append(Spacer(1, 6))

    print(f"Building PDF with {len(story)} flowable elements...")
    pdf_doc.build(story, canvasmaker=NumberedCanvas)
    print(f"PDF Successfully built: {pdf_path} ({os.path.getsize(pdf_path) / 1024:.1f} KB)")

if __name__ == "__main__":
    docx_file = "ACADEXSYNC_Complete_Project_Report.docx"
    pdf_file = "ACADEXSYNC_Complete_Project_Report.pdf"
    if os.path.exists(docx_file):
        build_pdf_from_docx(docx_file, pdf_file)
    else:
        print("Error: docx file does not exist.")

