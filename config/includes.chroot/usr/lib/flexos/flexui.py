from __future__ import annotations

from PyQt6.QtCore import Qt
from PyQt6.QtGui import QIcon
from PyQt6.QtWidgets import (
    QApplication,
    QFrame,
    QGridLayout,
    QLabel,
    QPushButton,
    QSizePolicy,
    QVBoxLayout,
    QWidget,
)

ACCENT = "#7c83ff"
BG = "#090c12"
SURFACE = "#10151e"
SURFACE_2 = "#151b26"
BORDER = "#273142"
TEXT = "#eef2f8"
MUTED = "#98a2b3"
SUCCESS = "#54d6a0"
WARNING = "#f5bf67"
DANGER = "#ff6b7a"

QSS = f"""
* {{
    font-family: "Noto Sans", "Inter", sans-serif;
    font-size: 14px;
    color: {TEXT};
}}
QMainWindow, QDialog, QWidget#appRoot {{
    background: {BG};
}}
QWidget {{
    background: transparent;
}}
QWidget#sidebar, QFrame#sidebar {{
    background: #0c1017;
    border-right: 1px solid {BORDER};
}}
QFrame#card {{
    background: {SURFACE};
    border: 1px solid {BORDER};
    border-radius: 14px;
}}
QFrame#softCard {{
    background: {SURFACE_2};
    border: 1px solid #202a3a;
    border-radius: 12px;
}}
QLabel#brand {{
    font-size: 22px;
    font-weight: 750;
    color: #ffffff;
}}
QLabel#eyebrow {{
    color: {ACCENT};
    font-size: 12px;
    font-weight: 700;
}}
QLabel#title, QLabel#hero {{
    color: #ffffff;
    font-size: 30px;
    font-weight: 750;
}}
QLabel#subtitle, QLabel#muted, QLabel#caption {{
    color: {MUTED};
}}
QLabel#section {{
    color: #ffffff;
    font-size: 17px;
    font-weight: 700;
}}
QLabel#metric {{
    color: #ffffff;
    font-size: 20px;
    font-weight: 700;
}}
QLabel#active {{
    background: #1b2131;
    border: 1px solid #303a52;
    color: #ffffff;
    padding: 9px 11px;
    border-radius: 9px;
    font-weight: 650;
}}
QLabel#step {{
    color: #788397;
    padding: 9px 11px;
}}
QListWidget {{
    background: transparent;
    border: 0;
    outline: 0;
    padding: 3px;
}}
QListWidget::item {{
    color: #aab4c5;
    min-height: 36px;
    padding: 5px 10px;
    margin: 2px 0;
    border-radius: 10px;
}}
QListWidget::item:hover {{
    background: #141a24;
    color: #ffffff;
}}
QListWidget::item:selected {{
    background: #1a2030;
    color: #ffffff;
    border-left: 3px solid {ACCENT};
}}
QLineEdit, QComboBox, QSpinBox, QDoubleSpinBox, QDateEdit, QTimeEdit,
QDateTimeEdit, QPlainTextEdit, QTextEdit, QListView, QTreeView, QTableView {{
    background: #0d121a;
    color: {TEXT};
    border: 1px solid {BORDER};
    border-radius: 10px;
    padding: 8px 10px;
    selection-background-color: #343b73;
    selection-color: #ffffff;
}}
QLineEdit {{
    min-height: 24px;
}}
QLineEdit:focus, QComboBox:focus, QPlainTextEdit:focus, QTextEdit:focus,
QListView:focus, QTreeView:focus, QTableView:focus {{
    border: 1px solid {ACCENT};
}}
QComboBox::drop-down {{
    width: 30px;
    border: 0;
}}
QComboBox QAbstractItemView {{
    background: {SURFACE_2};
    border: 1px solid {BORDER};
    selection-background-color: #2b3260;
    outline: 0;
}}
QPushButton {{
    min-height: 38px;
    background: #171e2a;
    border: 1px solid #2b3648;
    border-radius: 10px;
    padding: 2px 14px;
    font-weight: 600;
}}
QPushButton:hover {{
    background: #1d2635;
    border-color: #3a4860;
}}
QPushButton:pressed {{
    background: #121923;
}}
QPushButton:focus {{
    border: 1px solid {ACCENT};
}}
QPushButton[role="primary"] {{
    background: {ACCENT};
    color: #ffffff;
    border: 1px solid {ACCENT};
}}
QPushButton[role="primary"]:hover {{
    background: #8b91ff;
}}
QPushButton[role="danger"] {{
    background: #2a171d;
    color: #ff9aa5;
    border-color: #59303a;
}}
QPushButton[role="ghost"] {{
    background: transparent;
    border-color: transparent;
    color: #aeb8ca;
}}
QPushButton[role="ghost"]:hover {{
    background: #141a24;
    border-color: #202938;
}}
QPushButton:disabled {{
    color: #5f6877;
    background: #10151d;
    border-color: #1d2531;
}}
QCheckBox, QRadioButton {{
    spacing: 9px;
    color: #dce2ec;
}}
QCheckBox::indicator, QRadioButton::indicator {{
    width: 18px;
    height: 18px;
}}
QProgressBar {{
    min-height: 14px;
    background: #0d121a;
    border: 1px solid {BORDER};
    border-radius: 8px;
    text-align: center;
    color: #cfd7e5;
}}
QProgressBar::chunk {{
    background: {ACCENT};
    border-radius: 7px;
}}
QScrollArea {{
    border: 0;
    background: transparent;
}}
QScrollBar:vertical {{
    background: transparent;
    width: 11px;
    margin: 4px 1px;
}}
QScrollBar::handle:vertical {{
    background: #364156;
    min-height: 34px;
    border-radius: 5px;
}}
QScrollBar::handle:vertical:hover {{
    background: #4a5871;
}}
QScrollBar:horizontal {{
    background: transparent;
    height: 11px;
}}
QScrollBar::handle:horizontal {{
    background: #364156;
    min-width: 34px;
    border-radius: 5px;
}}
QScrollBar::add-line, QScrollBar::sub-line,
QScrollBar::add-page, QScrollBar::sub-page {{
    background: none;
    border: 0;
}}
QToolTip {{
    background: #171e29;
    color: #ffffff;
    border: 1px solid #344056;
    padding: 6px;
}}
QMessageBox {{
    background: {SURFACE};
}}
"""


def apply_theme(app: QApplication) -> None:
    app.setStyleSheet(QSS)


def icon(name: str) -> QIcon:
    return QIcon.fromTheme(name)


def label(text: str, role: str | None = None, wrap: bool = True) -> QLabel:
    item = QLabel(text)
    if role:
        item.setObjectName(role)
    item.setWordWrap(wrap)
    return item


def button(text: str, callback=None, role: str | None = None, icon_name: str | None = None) -> QPushButton:
    item = QPushButton(text)
    if role:
        item.setProperty("role", role)
    if icon_name:
        themed = icon(icon_name)
        if not themed.isNull():
            item.setIcon(themed)
    if callback:
        item.clicked.connect(callback)
    item.setCursor(Qt.CursorShape.PointingHandCursor)
    return item


def card(title_text: str | None = None, body: str | None = None, soft: bool = False):
    frame = QFrame()
    frame.setObjectName("softCard" if soft else "card")
    layout = QVBoxLayout(frame)
    layout.setContentsMargins(16, 15, 16, 15)
    layout.setSpacing(8)
    if title_text:
        layout.addWidget(label(title_text, "section"))
    if body is not None:
        body_label = label(body or "—", "caption")
        body_label.setTextInteractionFlags(Qt.TextInteractionFlag.TextSelectableByMouse)
        layout.addWidget(body_label)
    return frame, layout


def action_grid(actions: list[tuple], columns: int = 2) -> QWidget:
    host = QWidget()
    grid = QGridLayout(host)
    grid.setContentsMargins(0, 0, 0, 0)
    grid.setHorizontalSpacing(10)
    grid.setVerticalSpacing(10)
    for index, action in enumerate(actions):
        text, callback, *rest = action
        role = rest[0] if rest else None
        icon_name = rest[1] if len(rest) > 1 else None
        item = button(text, callback, role, icon_name)
        item.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Fixed)
        grid.addWidget(item, index // columns, index % columns)
    return host
