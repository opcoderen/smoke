import os

# dmgbuild 配置：带背景图与拖拽引导的安装界面
# 用法：dmgbuild -s dmg-settings.py -D app=build/SmokeLog.app -D background=build/dmg-bg.png SmokeLog out.dmg

app = defines.get("app")
bg = defines.get("background")

format = "UDZO"          # 压缩只读
files = [app]
symlinks = {"Applications": "/Applications"}
background = bg

# 窗口外观
default_view = "icon-view"
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
arrange_by = None
icon_size = 110
text_size = 13
label_pos = "bottom"

# 窗口大小与背景图（660x420 pt）一致
window_rect = ((240, 200), (660, 420))

# 图标摆放（原点在左下角，与背景图绘制坐标一致）
icon_locations = {
    os.path.basename(app): (170, 210),
    "Applications": (490, 210),
}
