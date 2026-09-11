#!/usr/bin/env python3
"""
Generate Professional Executive Presentation for Cable Ops CMMS.
Adheres strictly to the Industrial Dark Theme palette (Deep Slate, Charcoal, Slate-White, Cyan, Emerald, Amber, Crimson).
"""

from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.enum.shapes import MSO_SHAPE

# ==============================================================================
# INDUSTRIAL DARK PALETTE DESIGN SYSTEM
# ==============================================================================
COLOR_BG = RGBColor(15, 23, 42)          # Deep Slate #0F172A
COLOR_CARD = RGBColor(30, 41, 59)        # Charcoal #1E293B
COLOR_CARD_BORDER = RGBColor(51, 65, 85) # Slate Border #334155
COLOR_WHITE = RGBColor(241, 245, 249)    # Crisp Slate-White #F1F5F9
COLOR_MUTED = RGBColor(148, 163, 184)    # Muted Slate #94A3B8
COLOR_CYAN = RGBColor(6, 182, 212)       # Cyber Cyan #06B6D4
COLOR_EMERALD = RGBColor(16, 185, 129)   # Emerald Green #10B981
COLOR_AMBER = RGBColor(245, 158, 11)     # Amber Gold #F59E0B
COLOR_CRIMSON = RGBColor(239, 68, 68)    # Subdued Crimson #EF4444
COLOR_BLUE = RGBColor(59, 130, 246)      # Electric Blue #3B82F6
COLOR_PURPLE = RGBColor(168, 85, 247)    # Accent Purple #A855F7

FONT_NAME = "Segoe UI"

def set_slide_background(slide):
    """Fill slide background with Deep Slate #0F172A."""
    bg_shape = slide.shapes.add_shape(
        MSO_SHAPE.RECTANGLE, Inches(0), Inches(0), Inches(13.333), Inches(7.5)
    )
    bg_shape.fill.solid()
    bg_shape.fill.fore_color.rgb = COLOR_BG
    bg_shape.line.fill.background()
    return bg_shape

def add_header(slide, tag: str, title: str, subtitle: str):
    """Standardized industrial header for content slides."""
    # Tag chip / category
    tag_box = slide.shapes.add_textbox(Inches(0.8), Inches(0.45), Inches(11.5), Inches(0.35))
    tf_tag = tag_box.text_frame
    tf_tag.word_wrap = True
    tf_tag.margin_left = tf_tag.margin_top = tf_tag.margin_right = tf_tag.margin_bottom = 0
    p_tag = tf_tag.paragraphs[0]
    p_tag.text = tag.upper()
    p_tag.font.name = FONT_NAME
    p_tag.font.size = Pt(10)
    p_tag.font.bold = True
    p_tag.font.color.rgb = COLOR_CYAN

    # Title
    title_box = slide.shapes.add_textbox(Inches(0.8), Inches(0.8), Inches(11.5), Inches(0.55))
    tf_title = title_box.text_frame
    tf_title.word_wrap = True
    tf_title.margin_left = tf_title.margin_top = tf_title.margin_right = tf_title.margin_bottom = 0
    p_title = tf_title.paragraphs[0]
    p_title.text = title
    p_title.font.name = FONT_NAME
    p_title.font.size = Pt(24)
    p_title.font.bold = True
    p_title.font.color.rgb = COLOR_WHITE

    # Subtitle
    sub_box = slide.shapes.add_textbox(Inches(0.8), Inches(1.4), Inches(11.5), Inches(0.35))
    tf_sub = sub_box.text_frame
    tf_sub.word_wrap = True
    tf_sub.margin_left = tf_sub.margin_top = tf_sub.margin_right = tf_sub.margin_bottom = 0
    p_sub = tf_sub.paragraphs[0]
    p_sub.text = subtitle
    p_sub.font.name = FONT_NAME
    p_sub.font.size = Pt(12)
    p_sub.font.color.rgb = COLOR_MUTED

def add_card(slide, left, top, width, height, border_color=COLOR_CARD_BORDER):
    """Draw a styled dark card container."""
    card = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, left, top, width, height)
    card.fill.solid()
    card.fill.fore_color.rgb = COLOR_CARD
    card.line.color.rgb = border_color
    card.line.width = Pt(1.5)
    return card

# ==============================================================================
# BUILD PRESENTATION
# ==============================================================================
def create_presentation():
    prs = Presentation()
    prs.slide_width = Inches(13.333)
    prs.slide_height = Inches(7.5)
    blank_layout = prs.slide_layouts[6]

    # --------------------------------------------------------------------------
    # SLIDE 1: Title Slide (Dark Industrial Cover)
    # --------------------------------------------------------------------------
    slide1 = prs.slides.add_slide(blank_layout)
    set_slide_background(slide1)

    # Decorative top glow accent
    accent_bar = slide1.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0.8), Inches(1.2), Inches(0.12), Inches(2.2))
    accent_bar.fill.solid()
    accent_bar.fill.fore_color.rgb = COLOR_CYAN
    accent_bar.line.fill.background()

    # Category Badge
    badge_box = slide1.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(1.15), Inches(1.2), Inches(3.4), Inches(0.38))
    badge_box.fill.solid()
    badge_box.fill.fore_color.rgb = RGBColor(8, 47, 73) # Cyan-950
    badge_box.line.color.rgb = COLOR_CYAN
    badge_box.line.width = Pt(1.0)
    tf_badge = badge_box.text_frame
    tf_badge.vertical_anchor = MSO_ANCHOR.MIDDLE
    p_badge = tf_badge.paragraphs[0]
    p_badge.text = "CABLE INDUSTRY ENTERPRISE CMMS"
    p_badge.font.name = FONT_NAME
    p_badge.font.size = Pt(10)
    p_badge.font.bold = True
    p_badge.font.color.rgb = COLOR_CYAN
    p_badge.alignment = PP_ALIGN.CENTER

    # Main Title
    title_box = slide1.shapes.add_textbox(Inches(1.15), Inches(1.7), Inches(11.0), Inches(1.1))
    tf_main = title_box.text_frame
    tf_main.word_wrap = True
    p_main = tf_main.paragraphs[0]
    p_main.text = "Cable Ops CMMS"
    p_main.font.name = FONT_NAME
    p_main.font.size = Pt(46)
    p_main.font.bold = True
    p_main.font.color.rgb = COLOR_WHITE

    # Subtitle
    sub_box = slide1.shapes.add_textbox(Inches(1.15), Inches(2.8), Inches(10.5), Inches(0.8))
    tf_s1 = sub_box.text_frame
    tf_s1.word_wrap = True
    p_s1 = tf_s1.paragraphs[0]
    p_s1.text = "Unified Shop-Floor Operations, Downtime Handshake & Predictive Maintenance Engine"
    p_s1.font.name = FONT_NAME
    p_s1.font.size = Pt(18)
    p_s1.font.color.rgb = COLOR_MUTED

    # 3 Metadata highlight cards at bottom
    highlights = [
        ("PRODUCTION RELEASE", "Release v1.0 • Ready for Shop Floor", COLOR_EMERALD),
        ("FACTORY FLEET SCALE", "54 Continuous Machines • 7 Departments", COLOR_CYAN),
        ("SHIFT CHRONOLOGY", "3 Continuous Operating Shifts • 24/7", COLOR_AMBER),
    ]

    card_w = Inches(3.64)
    card_h = Inches(1.6)
    gap = Inches(0.35)
    start_x = Inches(0.8)
    top_y = Inches(4.8)

    for i, (head, desc, color) in enumerate(highlights):
        c_x = start_x + i * (card_w + gap)
        c = add_card(slide1, c_x, top_y, card_w, card_h, border_color=color)
        
        # Color accent strip on card
        strip = slide1.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, c_x + Inches(0.2), top_y + Inches(0.2), Inches(0.08), Inches(1.2))
        strip.fill.solid()
        strip.fill.fore_color.rgb = color
        strip.line.fill.background()

        tb = slide1.shapes.add_textbox(c_x + Inches(0.4), top_y + Inches(0.25), card_w - Inches(0.55), Inches(1.1))
        tf = tb.text_frame
        tf.word_wrap = True
        p1 = tf.paragraphs[0]
        p1.text = head
        p1.font.name = FONT_NAME
        p1.font.size = Pt(10)
        p1.font.bold = True
        p1.font.color.rgb = color

        p2 = tf.add_paragraph()
        p2.text = desc
        p2.font.name = FONT_NAME
        p2.font.size = Pt(13)
        p2.font.bold = True
        p2.font.color.rgb = COLOR_WHITE
        p2.space_before = Pt(6)

    # --------------------------------------------------------------------------
    # SLIDE 2: Factory Shop-Floor Challenges (The Problem)
    # --------------------------------------------------------------------------
    slide2 = prs.slides.add_slide(blank_layout)
    set_slide_background(slide2)
    add_header(
        slide2,
        tag="Manufacturing Pain Points",
        title="Factory Shop-Floor Challenges",
        subtitle="Critical operational bottlenecks that degrade overall equipment effectiveness (OEE) and inflate MTTR"
    )

    challenges = [
        (
            "1. Reporting Lag & Blind Stoppages",
            "Operators delay notifying maintenance during micro-stoppages and trips. Machines sit idle for 20-45 minutes before a technician is dispatched, creating untracked loss gaps.",
            "Impact: High Unplanned Downtime",
            COLOR_CRIMSON
        ),
        (
            "2. The Downtime Blame Game",
            "Production blames Maintenance for machine failure; Maintenance blames Production for operator error or raw material defects. No single source of truth exists.",
            "Impact: Unresolved Root Causes",
            COLOR_AMBER
        ),
        (
            "3. Distorted Shift Metrics",
            "When breakdowns occur near shift handover (e.g. 15:00 to 16:30), downtime attribution becomes distorted. Next shift refuses to inherit previous shift's downtime penalty.",
            "Impact: Inaccurate Shift OEE Accounting",
            COLOR_BLUE
        ),
        (
            "4. Paper Logs & Missing Part Traceability",
            "Stoppage forms and maintenance work orders on paper get lost, damaged by coolant oil, or filled retroactively with fabricated timestamps and unaccounted parts.",
            "Impact: Non-Audit-Ready Operations",
            COLOR_PURPLE
        ),
    ]

    grid_w = Inches(5.6)
    grid_h = Inches(2.2)
    xs = [Inches(0.8), Inches(6.9)]
    ys = [Inches(2.1), Inches(4.7)]

    for idx, (head, body, tag_val, color) in enumerate(challenges):
        col = idx % 2
        row = idx // 2
        cx = xs[col]
        cy = ys[row]

        card = add_card(slide2, cx, cy, grid_w, grid_h)

        # Left border indicator
        indicator = slide2.shapes.add_shape(MSO_SHAPE.RECTANGLE, cx, cy + Inches(0.2), Inches(0.08), grid_h - Inches(0.4))
        indicator.fill.solid()
        indicator.fill.fore_color.rgb = color
        indicator.line.fill.background()

        tb = slide2.shapes.add_textbox(cx + Inches(0.25), cy + Inches(0.2), grid_w - Inches(0.45), grid_h - Inches(0.4))
        tf = tb.text_frame
        tf.word_wrap = True

        p1 = tf.paragraphs[0]
        p1.text = head
        p1.font.name = FONT_NAME
        p1.font.size = Pt(14)
        p1.font.bold = True
        p1.font.color.rgb = COLOR_WHITE

        p2 = tf.add_paragraph()
        p2.text = body
        p2.font.name = FONT_NAME
        p2.font.size = Pt(11)
        p2.font.color.rgb = COLOR_MUTED
        p2.space_before = Pt(6)

        p3 = tf.add_paragraph()
        p3.text = tag_val.upper()
        p3.font.name = FONT_NAME
        p3.font.size = Pt(9.5)
        p3.font.bold = True
        p3.font.color.rgb = color
        p3.space_before = Pt(8)

    # --------------------------------------------------------------------------
    # SLIDE 3: The Cable Ops Solution (Core Architecture)
    # --------------------------------------------------------------------------
    slide3 = prs.slides.add_slide(blank_layout)
    set_slide_background(slide3)
    add_header(
        slide3,
        tag="Platform Architecture",
        title="The Cable Ops Solution",
        subtitle="A resilient industrial CMMS architected specifically for continuous cable production lines"
    )

    pillars = [
        (
            "54 Monitored Assets Across 7 Departments",
            "Pre-configured digital asset catalog covering every critical manufacturing stage:\n• Rod Breakdown & Medium Wire Drawing\n• High-Speed Bunchers & Rigid Stranders\n• CCV Continuous Vulcanization Lines\n• Sheathing & Insulation Extruders\n• Planetary Armouring & Drum Twisters",
            COLOR_CYAN
        ),
        (
            "Industrial Offline-First Resilience",
            "High-noise metal plants suffer frequent Wi-Fi dead zones.\n• Local Hive NoSQL persistent storage\n• Instant UI responsiveness during dropouts\n• Silent automatic background sync when connection recovers\n• Guaranteed zero data loss during plant-wide outages",
            COLOR_EMERALD
        ),
        (
            "Closed-Loop 2-Tier Handshake",
            "Enforces accountability between departments:\n• Operators initiate and verify line readiness\n• Technicians log root cause & spare parts\n• Supervisors retain exclusive triage and closure authority\n• Eliminates unauthorized line restarts and undocumented fixes",
            COLOR_AMBER
        ),
        (
            "Real-Time Plant Telemetry & OEE",
            "Instant situational awareness for factory leadership:\n• Real-time Machine Status (Running, Idle, Under Repair)\n• Automated MTTR & MTBF Calculation Engine\n• Pareto Downtime Root-Cause Analysis\n• Departmental filtering and multi-shift aggregations",
            COLOR_BLUE
        ),
    ]

    col_w = Inches(2.76)
    col_h = Inches(4.8)
    col_gap = Inches(0.24)
    start_left = Inches(0.8)

    for i, (head, desc, color) in enumerate(pillars):
        c_left = start_left + i * (col_w + col_gap)
        add_card(slide3, c_left, Inches(2.1), col_w, col_h, border_color=color)

        # Header bar in card
        hbar = slide3.shapes.add_shape(MSO_SHAPE.RECTANGLE, c_left + Inches(0.15), Inches(2.25), col_w - Inches(0.3), Inches(0.06))
        hbar.fill.solid()
        hbar.fill.fore_color.rgb = color
        hbar.line.fill.background()

        tb = slide3.shapes.add_textbox(c_left + Inches(0.15), Inches(2.45), col_w - Inches(0.3), col_h - Inches(0.5))
        tf = tb.text_frame
        tf.word_wrap = True

        p1 = tf.paragraphs[0]
        p1.text = head
        p1.font.name = FONT_NAME
        p1.font.size = Pt(13)
        p1.font.bold = True
        p1.font.color.rgb = COLOR_WHITE

        p2 = tf.add_paragraph()
        p2.text = desc
        p2.font.name = FONT_NAME
        p2.font.size = Pt(10.5)
        p2.font.color.rgb = COLOR_MUTED
        p2.space_before = Pt(10)

    # --------------------------------------------------------------------------
    # SLIDE 4: The 5-Step Handshake Lifecycle
    # --------------------------------------------------------------------------
    slide4 = prs.slides.add_slide(blank_layout)
    set_slide_background(slide4)
    add_header(
        slide4,
        tag="State Machine Integrity",
        title="The 5-Step Handshake Lifecycle",
        subtitle="Enforcing strict sequential authorization across operations, engineering, and maintenance"
    )

    steps = [
        (
            "STEP 1",
            "Report Stoppage",
            "PENDING",
            "Line Operator",
            "Operator scans machine QR code or selects asset, picks fault preset, and logs downtime reason.",
            COLOR_CRIMSON
        ),
        (
            "STEP 2",
            "Triage & Assign",
            "ASSIGNED",
            "Maint. Supervisor",
            "Supervisor reviews priority (Critical/High), matches technician specialty (Electrical/Mechanical), and dispatches.",
            COLOR_BLUE
        ),
        (
            "STEP 3",
            "Field Repair",
            "IN_PROGRESS",
            "Maintenance Tech",
            "Tech taps 'Start Repair' (initiates live stopwatch), conducts fix, consumes spare parts, and inputs root cause.",
            COLOR_PURPLE
        ),
        (
            "STEP 4",
            "Quality Test Run",
            "VERIFIED",
            "Line Operator",
            "Operator confirms machine runs in specification (spark test, diameter, speed) and certifies line restoration.",
            COLOR_CYAN
        ),
        (
            "STEP 5",
            "Approve & Close",
            "CLOSED",
            "Maint. Supervisor",
            "Supervisor audits complete activity log, validates parts expenditure, and formally seals the work order.",
            COLOR_EMERALD
        ),
    ]

    card_w4 = Inches(2.18)
    card_h4 = Inches(4.7)
    gap4 = Inches(0.21)
    start_x4 = Inches(0.8)

    for i, (s_num, s_title, s_status, s_actor, s_desc, s_color) in enumerate(steps):
        cx = start_x4 + i * (card_w4 + gap4)
        add_card(slide4, cx, Inches(2.15), card_w4, card_h4, border_color=s_color)

        tb = slide4.shapes.add_textbox(cx + Inches(0.12), Inches(2.3), card_w4 - Inches(0.24), card_h4 - Inches(0.3))
        tf = tb.text_frame
        tf.word_wrap = True

        p_num = tf.paragraphs[0]
        p_num.text = s_num
        p_num.font.name = FONT_NAME
        p_num.font.size = Pt(11)
        p_num.font.bold = True
        p_num.font.color.rgb = s_color

        p_tit = tf.add_paragraph()
        p_tit.text = s_title
        p_tit.font.name = FONT_NAME
        p_tit.font.size = Pt(14)
        p_tit.font.bold = True
        p_tit.font.color.rgb = COLOR_WHITE
        p_tit.space_before = Pt(4)

        # Status badge
        p_stat = tf.add_paragraph()
        p_stat.text = f"STATUS: {s_status}"
        p_stat.font.name = FONT_NAME
        p_stat.font.size = Pt(9.5)
        p_stat.font.bold = True
        p_stat.font.color.rgb = s_color
        p_stat.space_before = Pt(8)

        # Actor badge
        p_act = tf.add_paragraph()
        p_act.text = f"ACTOR: {s_actor}"
        p_act.font.name = FONT_NAME
        p_act.font.size = Pt(9.5)
        p_act.font.bold = True
        p_act.font.color.rgb = COLOR_WHITE
        p_act.space_before = Pt(4)

        # Description
        p_desc = tf.add_paragraph()
        p_desc.text = s_desc
        p_desc.font.name = FONT_NAME
        p_desc.font.size = Pt(10.5)
        p_desc.font.color.rgb = COLOR_MUTED
        p_desc.space_before = Pt(12)

    # --------------------------------------------------------------------------
    # SLIDE 5: Role-Based Access Control (RBAC Matrix)
    # --------------------------------------------------------------------------
    slide5 = prs.slides.add_slide(blank_layout)
    set_slide_background(slide5)
    add_header(
        slide5,
        tag="Security & Governance",
        title="Role-Based Access Control (RBAC Matrix)",
        subtitle="3-tier defense-in-depth permission scopes preventing cross-role tampering and unauthorized sign-offs"
    )

    # Table layout
    rows = 6
    cols = 4
    left = Inches(0.8)
    top = Inches(2.15)
    width = Inches(11.733)
    height = Inches(4.7)

    table_shape = slide5.shapes.add_table(rows, cols, left, top, width, height)
    table = table_shape.table

    # Column widths
    table.columns[0].width = Inches(2.2)  # Role
    table.columns[1].width = Inches(2.2)  # Scope
    table.columns[2].width = Inches(4.5)  # Permitted Actions
    table.columns[3].width = Inches(2.833) # Restrictions

    headers = ["OPERATIONAL ROLE", "SECURITY SCOPE", "PERMITTED ACTIONS", "RESTRICTIONS"]
    for c_idx, h_text in enumerate(headers):
        cell = table.cell(0, c_idx)
        cell.fill.solid()
        cell.fill.fore_color.rgb = RGBColor(15, 23, 42)
        p = cell.text_frame.paragraphs[0]
        p.text = h_text
        p.font.name = FONT_NAME
        p.font.size = Pt(11)
        p.font.bold = True
        p.font.color.rgb = COLOR_CYAN
        p.alignment = PP_ALIGN.LEFT

    rbac_data = [
        (
            "Line Operator",
            "Assigned Department",
            "Scan machine QR, report breakdown, view line work orders, confirm test run (VERIFIED)",
            "Cannot assign technicians, start technical repair, or close tickets"
        ),
        (
            "Maintenance Tech",
            "Assigned Work Orders",
            "Start repair (live MTTR timer), log consumed spare parts, input root cause, mark complete",
            "Cannot create work orders, reassign colleagues, or execute final sign-off"
        ),
        (
            "Maint. Supervisor",
            "Plant-Wide Maintenance",
            "Triage priority, dispatch specialized techs, approve parts, execute final ticket sign-off (CLOSED)",
            "Cannot bypass operator test-run sign-off or alter historical timestamps"
        ),
        (
            "Prod. Supervisor",
            "Production Lines",
            "Log process/material stoppages, monitor line availability, manage shift handover summaries",
            "Cannot assign maintenance techs or close technical engineering work orders"
        ),
        (
            "Plant / Exec Manager",
            "Factory-Wide",
            "Executive OEE dashboard, MTTR/MTBF analytics, Pareto loss analysis, PM compliance audits",
            "Read-only operational access; all state-transition action buttons locked"
        ),
    ]

    for r_idx, row_values in enumerate(rbac_data, start=1):
        # Alternate row background
        row_bg = RGBColor(30, 41, 59) if r_idx % 2 == 1 else RGBColor(24, 33, 47)
        for c_idx, val in enumerate(row_values):
            cell = table.cell(r_idx, c_idx)
            cell.fill.solid()
            cell.fill.fore_color.rgb = row_bg
            p = cell.text_frame.paragraphs[0]
            p.text = val
            p.font.name = FONT_NAME
            p.font.size = Pt(10)
            if c_idx == 0:
                p.font.bold = True
                p.font.color.rgb = COLOR_WHITE
            elif c_idx == 3:
                p.font.color.rgb = RGBColor(248, 113, 113) # Light Crimson
            else:
                p.font.color.rgb = COLOR_MUTED

    # --------------------------------------------------------------------------
    # SLIDE 6: Continuous Shift Engine & Audit Trail
    # --------------------------------------------------------------------------
    slide6 = prs.slides.add_slide(blank_layout)
    set_slide_background(slide6)
    add_header(
        slide6,
        tag="Chronology & Traceability",
        title="Continuous Shift Engine & Immutable Audit Trail",
        subtitle="Automated plant-wide temporal attribution and tamper-proof operational logging"
    )

    half_w = Inches(5.7)
    card_h6 = Inches(4.8)

    # Left Card: Shift Allocation Engine
    left_card = add_card(slide6, Inches(0.8), Inches(2.1), half_w, card_h6, border_color=COLOR_CYAN)
    tb_l = slide6.shapes.add_textbox(Inches(1.0), Inches(2.3), half_w - Inches(0.4), card_h6 - Inches(0.4))
    tf_l = tb_l.text_frame
    tf_l.word_wrap = True

    p_l1 = tf_l.paragraphs[0]
    p_l1.text = "3-Shift Continuous Operational Engine"
    p_l1.font.name = FONT_NAME
    p_l1.font.size = Pt(15)
    p_l1.font.bold = True
    p_l1.font.color.rgb = COLOR_CYAN

    p_l2 = tf_l.add_paragraph()
    p_l2.text = "The plant operates 24 hours continuously under three minute-precise shifts:\n" \
                "• Shift 1 (Morning): 07:30 to 15:30 (8.0 Hours)\n" \
                "• Shift 2 (Evening): 15:30 to 23:00 (7.5 Hours)\n" \
                "• Shift 3 (Night):   23:00 to 07:30 (+1 Day) (8.5 Hours)"
    p_l2.font.name = FONT_NAME
    p_l2.font.size = Pt(11)
    p_l2.font.color.rgb = COLOR_WHITE
    p_l2.space_before = Pt(8)

    p_l3 = tf_l.add_paragraph()
    p_l3.text = "Cross-Shift Carryover Calculation (حالة استمرار العطل):"
    p_l3.font.name = FONT_NAME
    p_l3.font.size = Pt(12)
    p_l3.font.bold = True
    p_l3.font.color.rgb = COLOR_AMBER
    p_l3.space_before = Pt(14)

    p_l4 = tf_l.add_paragraph()
    p_l4.text = "When a breakdown begins in Shift 1 (e.g. 14:00) and concludes in Shift 2 (e.g. 17:00):\n" \
                "1. Ticket is automatically flagged as isCrossShift: true.\n" \
                "2. System splits downtime duration cleanly: exactly 90 minutes allocated to Shift 1 and 90 minutes to Shift 2.\n" \
                "3. Eliminates shift handover disputes during OEE accounting."
    p_l4.font.name = FONT_NAME
    p_l4.font.size = Pt(10.5)
    p_l4.font.color.rgb = COLOR_MUTED
    p_l4.space_before = Pt(6)

    # Right Card: Tamper-Proof Audit Trail
    right_card = add_card(slide6, Inches(6.833), Inches(2.1), half_w, card_h6, border_color=COLOR_EMERALD)
    tb_r = slide6.shapes.add_textbox(Inches(7.033), Inches(2.3), half_w - Inches(0.4), card_h6 - Inches(0.4))
    tf_r = tb_r.text_frame
    tf_r.word_wrap = True

    p_r1 = tf_r.paragraphs[0]
    p_r1.text = "Immutable Event Audit Trail"
    p_r1.font.name = FONT_NAME
    p_r1.font.size = Pt(15)
    p_r1.font.bold = True
    p_r1.font.color.rgb = COLOR_EMERALD

    p_r2 = tf_r.add_paragraph()
    p_r2.text = "Every state transition across the 5-step lifecycle generates an append-only digital event log:"
    p_r2.font.name = FONT_NAME
    p_r2.font.size = Pt(11)
    p_r2.font.color.rgb = COLOR_WHITE
    p_r2.space_before = Pt(8)

    p_r3 = tf_r.add_paragraph()
    p_r3.text = "• Silent Session Extraction: Captures actor Full Name, Corporate Email, and Role code without manual user entry.\n" \
                "• Automated Dual Timestamps: Machine-accurate UTC for programmatic calculation ($MTTR$) + localized Plant Clock format.\n" \
                "• Granular Action Metadata: Records spare parts deducted, root cause notes, and test-run performance metrics.\n" \
                "• Non-Repudiation: Neither operators nor supervisors can edit or back-date past maintenance records."
    p_r3.font.name = FONT_NAME
    p_r3.font.size = Pt(10.5)
    p_r3.font.color.rgb = COLOR_MUTED
    p_r3.space_before = Pt(8)

    p_r4 = tf_r.add_paragraph()
    p_r4.text = "CERTIFIED AUDIT COMPLIANCE"
    p_r4.font.name = FONT_NAME
    p_r4.font.size = Pt(11)
    p_r4.font.bold = True
    p_r4.font.color.rgb = COLOR_CYAN
    p_r4.space_before = Pt(16)

    p_r5 = tf_r.add_paragraph()
    p_r5.text = "Full historical trace available for ISO 9001 quality audits, machine warranty claims, and Root Cause Failure Analyses (RCFA)."
    p_r5.font.name = FONT_NAME
    p_r5.font.size = Pt(10.5)
    p_r5.font.color.rgb = COLOR_MUTED
    p_r5.space_before = Pt(4)

    # --------------------------------------------------------------------------
    # SLIDE 7: Business Impact & Factory ROI
    # --------------------------------------------------------------------------
    slide7 = prs.slides.add_slide(blank_layout)
    set_slide_background(slide7)
    add_header(
        slide7,
        tag="Value Realization",
        title="Business Impact & Manufacturing ROI",
        subtitle="Transforming reactive firefighting into predictable, high-yield cable production"
    )

    metrics = [
        (
            "-35%",
            "Unplanned Stoppage Duration",
            "Instant QR dispatch and live MTTR stopwatches eliminate response latency. Machine turnaround accelerates significantly.",
            COLOR_CRIMSON
        ),
        (
            "100%",
            "Downtime Attribution",
            "Clear division between Process Stoppages and Technical Failures eliminates friction between Production and Maintenance.",
            COLOR_CYAN
        ),
        (
            "Zero",
            "Shift Handover Loss",
            "Digital cross-shift tracking and automated pending-order carryover ensure incoming shift supervisors have 100% situational awareness.",
            COLOR_AMBER
        ),
    ]

    metric_w = Inches(3.64)
    metric_h = Inches(3.2)
    m_gap = Inches(0.4)
    m_start_x = Inches(0.8)

    for i, (stat, m_title, m_desc, m_color) in enumerate(metrics):
        mx = m_start_x + i * (metric_w + m_gap)
        add_card(slide7, mx, Inches(2.1), metric_w, metric_h, border_color=m_color)

        tb = slide7.shapes.add_textbox(mx + Inches(0.2), Inches(2.3), metric_w - Inches(0.4), metric_h - Inches(0.5))
        tf = tb.text_frame
        tf.word_wrap = True

        p_stat = tf.paragraphs[0]
        p_stat.text = stat
        p_stat.font.name = FONT_NAME
        p_stat.font.size = Pt(42)
        p_stat.font.bold = True
        p_stat.font.color.rgb = m_color

        p_title = tf.add_paragraph()
        p_title.text = m_title
        p_title.font.name = FONT_NAME
        p_title.font.size = Pt(14)
        p_title.font.bold = True
        p_title.font.color.rgb = COLOR_WHITE
        p_title.space_before = Pt(4)

        p_desc = tf.add_paragraph()
        p_desc.text = m_desc
        p_desc.font.name = FONT_NAME
        p_desc.font.size = Pt(11)
        p_desc.font.color.rgb = COLOR_MUTED
        p_desc.space_before = Pt(10)

    # Bottom Summary Banner
    banner = add_card(slide7, Inches(0.8), Inches(5.6), Inches(11.733), Inches(1.3), border_color=COLOR_EMERALD)
    tb_b = slide7.shapes.add_textbox(Inches(1.1), Inches(5.75), Inches(11.1), Inches(1.0))
    tf_b = tb_b.text_frame
    tf_b.word_wrap = True

    p_b1 = tf_b.paragraphs[0]
    p_b1.text = "EXECUTIVE DEPLOYMENT READINESS"
    p_b1.font.name = FONT_NAME
    p_b1.font.size = Pt(11)
    p_b1.font.bold = True
    p_b1.font.color.rgb = COLOR_EMERALD

    p_b2 = tf_b.add_paragraph()
    p_b2.text = "Cable Ops CMMS converts factory floor downtime into transparent, actionable engineering metrics. Ready for immediate deployment across all 54 cable manufacturing lines."
    p_b2.font.name = FONT_NAME
    p_b2.font.size = Pt(12)
    p_b2.font.bold = True
    p_b2.font.color.rgb = COLOR_WHITE
    p_b2.space_before = Pt(4)

    # Save presentation
    output_filename = "Cable_Ops_CMMS_Overview.pptx"
    prs.save(output_filename)
    print(f"[SUCCESS] Presentation generated: {output_filename}")

if __name__ == "__main__":
    create_presentation()
