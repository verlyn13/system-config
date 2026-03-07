# shellcheck shell=bash
plugin_register "android-studio-canary" "Android Studio Canary (Preview)" "curl python3" "false"

# Feed URL for all Android Studio releases (redirects via jb.gg)
_AS_RELEASES_URL="https://jb.gg/android-studio-releases-list.xml"
_AS_APP_NAME="Android Studio Preview.app"
_AS_INSTALL_DIR="/Applications"

# Python helper: parse feed XML, extract latest canary info for mac_arm
_as_canary_parse() {
  local xml_file="$1" action="$2"
  python3 - "$xml_file" "$action" <<'PYEOF'
import sys, xml.etree.ElementTree as ET

xml_file, action = sys.argv[1], sys.argv[2]
tree = ET.parse(xml_file)

for item in tree.findall('.//item'):
    if item.findtext('channel') != 'Canary':
        continue
    version = item.findtext('version', '')
    name = item.findtext('name', '')
    build = item.findtext('build', '')
    date = item.findtext('date', '')
    for dl in item.findall('download'):
        link = dl.findtext('link', '')
        if 'mac_arm.dmg' in link:
            checksum = dl.findtext('checksum', '')
            size = dl.findtext('size', '')
            if action == 'info':
                print(f"name={name}")
                print(f"version={version}")
                print(f"build={build}")
                print(f"date={date}")
                print(f"link={link}")
                print(f"checksum={checksum}")
                print(f"size={size}")
            elif action == 'version':
                print(version)
            elif action == 'link':
                print(link)
            elif action == 'checksum':
                print(checksum)
            sys.exit(0)
    # Found canary but no mac_arm download
    print(f"ERROR: No mac_arm.dmg download found for {name}", file=sys.stderr)
    sys.exit(1)

print("ERROR: No Canary channel entry found in feed", file=sys.stderr)
sys.exit(1)
PYEOF
}

# Get installed canary version from Info.plist
_as_canary_installed_version() {
  local plist="${_AS_INSTALL_DIR}/${_AS_APP_NAME}/Contents/Info.plist"
  if [[ ! -f "$plist" ]]; then
    echo "not-installed"
    return 0
  fi
  # CFBundleShortVersionString gives e.g. "2025.3"
  # CFBundleVersion gives full build like "AI-253.29346.138.2531.14682307"
  defaults read "${_AS_INSTALL_DIR}/${_AS_APP_NAME}/Contents/Info.plist" CFBundleVersion 2>/dev/null || echo "unknown"
}

check_android-studio-canary() {
  local feed_xml
  feed_xml="$(mktemp /tmp/tmp.system-update.XXXXXX)"

  echo "Fetching Android Studio releases feed..."
  if ! curl -sSL "$_AS_RELEASES_URL" -o "$feed_xml" 2>&1; then
    echo "Failed to fetch releases feed"
    rm -f "$feed_xml"
    return 1
  fi

  local info
  info="$(_as_canary_parse "$feed_xml" "info")" || {
    echo "Failed to parse releases feed"
    rm -f "$feed_xml"
    return 1
  }
  rm -f "$feed_xml"

  local remote_name remote_version remote_build remote_date
  remote_name="$(echo "$info" | grep '^name=' | cut -d= -f2-)"
  remote_version="$(echo "$info" | grep '^version=' | cut -d= -f2-)"
  remote_build="$(echo "$info" | grep '^build=' | cut -d= -f2-)"
  remote_date="$(echo "$info" | grep '^date=' | cut -d= -f2-)"

  local installed_build
  installed_build="$(_as_canary_installed_version)"

  echo "Latest canary:    ${remote_name} (${remote_version})"
  echo "  Build:          ${remote_build}"
  echo "  Released:       ${remote_date}"
  echo "Installed build:  ${installed_build}"

  if [[ "$installed_build" == "$remote_build" ]]; then
    echo "Status: up to date"
  elif [[ "$installed_build" == "not-installed" ]]; then
    echo "Status: not installed"
    echo "Download: https://developer.android.com/studio/preview"
  else
    echo "Status: update available"
    echo "Download: https://developer.android.com/studio/preview"
  fi
}

# run mode does the same as check — report status and provide download link.
# Automated DMG install is intentionally not implemented; update manually via:
#   https://developer.android.com/studio/preview
run_android-studio-canary() {
  check_android-studio-canary
}
