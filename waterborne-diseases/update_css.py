import re

file_path = "src/Dashboard.css"

with open(file_path, "r", encoding="utf-8") as f:
    css = f.read()

# Replace hardcoded hex colors
css = css.replace("#011C40", "#000000")
css = css.replace("#023859", "#000000")
css = css.replace("#26658C", "#3B82F6") # mapping to blue 500

# Replace rgba navy colors with simple white tint for glassmorphism
css = re.sub(r"rgba\(1,\s*28,\s*64,\s*[0-9.]+\)", "rgba(255, 255, 255, 0.03)", css)
css = re.sub(r"rgba\(2,\s*56,\s*89,\s*[0-9.]+\)", "rgba(255, 255, 255, 0.04)", css)
css = re.sub(r"rgba\(38,\s*101,\s*140,\s*[0-9.]+\)", "rgba(255, 255, 255, 0.05)", css)

# Replace accent colors that might be hardcoded as hex
css = css.replace("#54ACBF", "#3B82F6")
css = css.replace("#A7EBF2", "#06B6D4")

# Replace rgb equivalent of #54ACBF: 84, 172, 191 -> 59, 130, 246
css = re.sub(r"rgba\(84,\s*172,\s*191,\s*([0-9.]+)\)", r"rgba(59, 130, 246, \1)", css)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(css)

print("Updated Dashboard.css")
