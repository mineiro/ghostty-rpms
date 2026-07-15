%global zig_version 0.15.2
%global upstream_version 1.3.2-dev
%global commit c5a21edfcbc2d5b46540ad91b7980aca31f5f1f3
%global shortcommit c5a21ed
%global commitdate 20260715
%global srcdirname ghostty-%{commit}

%bcond_with legacy_terminfo_alias

Name:           ghostty-git
Version:        1.3.2.20260715gitc5a21ed
Release:        %autorelease
Summary:        Main-branch snapshot of the Ghostty terminal emulator

License:        MIT
URL:            https://github.com/ghostty-org/ghostty
Source0:        https://codeload.github.com/ghostty-org/ghostty/tar.gz/%{commit}#/%{srcdirname}.tar.gz
Source1:        https://ziglang.org/download/%{zig_version}/zig-x86_64-linux-%{zig_version}.tar.xz
Source2:        https://ziglang.org/download/%{zig_version}/zig-aarch64-linux-%{zig_version}.tar.xz
Source3:        ghostty-zig-cache-%{commit}.tar.zst
Patch0:         0001-add-build-id-to-libghostty-vt.patch

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

Provides:       ghostty = %{version}-%{release}
Conflicts:      ghostty
Recommends:     ghostty-themes

%package -n libghostty-vt-git
Summary:        Main-branch snapshot of the Ghostty VT/state parsing library
Provides:       libghostty-vt = %{version}-%{release}
Conflicts:      libghostty-vt

%description -n libghostty-vt-git
libghostty-vt-git is the reusable virtual-terminal parser and state engine from
an unreleased Ghostty main-branch snapshot.

%package -n libghostty-vt-git-devel
Summary:        Development files for libghostty-vt-git
Requires:       libghostty-vt-git%{?_isa} = %{version}-%{release}
Provides:       libghostty-vt-devel = %{version}-%{release}
Conflicts:      libghostty-vt-devel

%description -n libghostty-vt-git-devel
Headers and development metadata for building software against libghostty-vt-git.

%description
ghostty-git is an experimental package built from the latest tracked upstream
Ghostty main-branch snapshot. It installs the standard Ghostty binary and
desktop assets, so it conflicts with the stable ghostty package.

%prep
rm -rf "%{srcdirname}"
tar -xzf %{SOURCE0}
srcroot="$(tar -tf %{SOURCE0} | head -1 | cut -d/ -f1)"
if [ "$srcroot" != "%{srcdirname}" ]; then
  mv "$srcroot" "%{srcdirname}"
fi
pushd "%{srcdirname}"
tar --zstd -xf %{SOURCE3}
%autopatch -p1
popd

%build
: # build and install are performed together in %%install via `zig build`

%install
cd "%{srcdirname}"

%ifarch x86_64
tar -xJf %{SOURCE1}
export PATH="$PWD/zig-x86_64-linux-%{zig_version}:$PATH"
%endif
%ifarch aarch64
tar -xJf %{SOURCE2}
export PATH="$PWD/zig-aarch64-linux-%{zig_version}:$PATH"
%endif

DESTDIR=%{buildroot} zig build \
  --summary all \
  --system vendor/p \
  --prefix "%{_prefix}" \
  -Dversion-string=%{upstream_version}+%{commitdate}.git%{shortcommit}.rpm%{release} \
  -Doptimize=ReleaseFast \
  -Dcpu=baseline \
  -Dpie=true \
  -Demit-themes=false \
  -Demit-docs

mkdir -p "%{buildroot}%{_libdir}" "%{buildroot}%{_libdir}/pkgconfig"
if compgen -G "%{buildroot}%{_prefix}/lib/libghostty-vt.so*" > /dev/null; then
  mv "%{buildroot}%{_prefix}/lib"/libghostty-vt.so* "%{buildroot}%{_libdir}/"
fi
if [ -f "%{buildroot}%{_datadir}/pkgconfig/libghostty-vt.pc" ]; then
  mv "%{buildroot}%{_datadir}/pkgconfig/libghostty-vt.pc" "%{buildroot}%{_libdir}/pkgconfig/"
  sed -i 's#^libdir=.*#libdir=%{_libdir}#' "%{buildroot}%{_libdir}/pkgconfig/libghostty-vt.pc"
fi
# Upstream main currently installs a static VT archive whose members reference
# transient Zig cache paths. We do not ship static VT artifacts from this RPM.
rm -f "%{buildroot}%{_prefix}/lib/libghostty-vt.a"
rm -f "%{buildroot}%{_datadir}/pkgconfig/libghostty-vt-static.pc"

%if %{without legacy_terminfo_alias}
# Avoid alias conflicts with other terminfo providers.
rm -f "%{buildroot}%{_datadir}/terminfo/g/ghostty"
%endif

%check
test -x "%{buildroot}%{_bindir}/ghostty"

%files
%license %{srcdirname}/LICENSE
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
/usr/lib/systemd/user/app-com.mitchellh.ghostty.service
%{_mandir}/man1/ghostty.1*
%{_mandir}/man5/ghostty.5*
%{_datadir}/terminfo/x/xterm-ghostty
%if %{with legacy_terminfo_alias}
%{_datadir}/terminfo/g/ghostty
%endif

%files -n libghostty-vt-git
%{_libdir}/libghostty-vt.so.*

%files -n libghostty-vt-git-devel
%{_includedir}/ghostty
%{_libdir}/libghostty-vt.so
%{_libdir}/pkgconfig/libghostty-vt.pc

%changelog
%autochangelog
