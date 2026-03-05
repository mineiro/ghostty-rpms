%global zig_version 0.14.1

%bcond_with legacy_terminfo_alias

Name:           ghostty
Version:        1.2.3
Release:        %autorelease
Summary:        Fast, feature-rich terminal emulator with native Linux UI

License:        MIT
URL:            https://github.com/ghostty-org/ghostty
Source0:        %{url}/archive/refs/tags/v%{version}.tar.gz#/%{name}-%{version}.tar.gz
Source1:        https://ziglang.org/download/%{zig_version}/zig-linux-x86_64-%{zig_version}.tar.xz
Source2:        https://ziglang.org/download/%{zig_version}/zig-linux-aarch64-%{zig_version}.tar.xz

ExclusiveArch:  x86_64 aarch64

BuildRequires:  blueprint-compiler
BuildRequires:  fontconfig-devel
BuildRequires:  freetype-devel
BuildRequires:  glib2-devel
BuildRequires:  gtk4-devel
BuildRequires:  gtk4-layer-shell-devel
BuildRequires:  harfbuzz-devel
BuildRequires:  libadwaita-devel
BuildRequires:  libpng-devel
BuildRequires:  oniguruma-devel
BuildRequires:  pandoc-cli
BuildRequires:  pixman-devel
BuildRequires:  pkgconfig
BuildRequires:  wayland-protocols-devel
BuildRequires:  zlib-ng-devel

%package -n libghostty-vt
Summary:        Shared Ghostty VT/state parsing library

%description -n libghostty-vt
libghostty-vt is the reusable virtual-terminal parser and state engine extracted
from Ghostty for embedding in developer tools and applications.

%package -n libghostty-vt-devel
Summary:        Development files for libghostty-vt
Requires:       libghostty-vt%{?_isa} = %{version}-%{release}

%description -n libghostty-vt-devel
Headers and development metadata for building software against libghostty-vt.

%description
Ghostty is a fast terminal emulator with a native GTK-based Linux UI and GPU
acceleration.

%prep
%autosetup -p1

%build
: # build and install are performed together in %%install via `zig build`

%install
%ifarch x86_64
tar -xJf %{SOURCE1}
export PATH="$PWD/zig-linux-x86_64-%{zig_version}:$PATH"
%endif
%ifarch aarch64
tar -xJf %{SOURCE2}
export PATH="$PWD/zig-linux-aarch64-%{zig_version}:$PATH"
%endif

DESTDIR=%{buildroot} zig build \
  --summary all \
  --prefix "%{_prefix}" \
  -Dversion-string=%{version}-%{release} \
  -Doptimize=ReleaseFast \
  -Dcpu=baseline \
  -Dpie=true \
  -Demit-themes=false \
  -Demit-docs

%if %{without legacy_terminfo_alias}
# Avoid alias conflicts with other terminfo providers.
rm -f "%{buildroot}%{_datadir}/terminfo/g/ghostty"
%endif

%check
test -x "%{buildroot}%{_bindir}/ghostty"

%files
%license LICENSE
%{_bindir}/ghostty
%{_datadir}/applications/com.mitchellh.ghostty.desktop
%{_datadir}/bash-completion/completions/ghostty.bash
%{_datadir}/bat/syntaxes/ghostty.sublime-syntax
%{_datadir}/fish/vendor_completions.d/ghostty.fish
%{_datadir}/ghostty
%{_datadir}/icons/hicolor/*/apps/com.mitchellh.ghostty.png
%{_datadir}/kio/servicemenus/com.mitchellh.ghostty.desktop
%{_datadir}/nautilus-python/extensions/ghostty.py
%{_datadir}/nvim/site/compiler/ghostty.vim
%{_datadir}/nvim/site/ftdetect/ghostty.vim
%{_datadir}/nvim/site/ftplugin/ghostty.vim
%{_datadir}/nvim/site/syntax/ghostty.vim
%{_datadir}/vim/vimfiles/compiler/ghostty.vim
%{_datadir}/vim/vimfiles/ftdetect/ghostty.vim
%{_datadir}/vim/vimfiles/ftplugin/ghostty.vim
%{_datadir}/vim/vimfiles/syntax/ghostty.vim
%{_datadir}/zsh/site-functions/_ghostty
%{_datadir}/dbus-1/services/com.mitchellh.ghostty.service
%{_datadir}/locale/*/LC_MESSAGES/com.mitchellh.ghostty.mo
%{_datadir}/metainfo/com.mitchellh.ghostty.metainfo.xml
%{_datadir}/systemd/user/app-com.mitchellh.ghostty.service
%{_mandir}/man1/ghostty.1*
%{_mandir}/man5/ghostty.5*
%{_datadir}/terminfo/x/xterm-ghostty
%if %{with legacy_terminfo_alias}
%{_datadir}/terminfo/g/ghostty
%endif

%files -n libghostty-vt
%{_libdir}/libghostty-vt.so.*

%files -n libghostty-vt-devel
%{_includedir}/ghostty
%{_libdir}/libghostty-vt.so
%{_datadir}/pkgconfig/libghostty-vt.pc

%changelog
%autochangelog
