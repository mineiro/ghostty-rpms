%global zig_version 0.15.2
%global commit 32c2dd5cd691c6bf226535be5ff7ec099ddd3360
%global shortcommit 32c2dd5
%global commitdate 20260406
%global ghostty_commit fdb6e3d2c8543e2e756b7e07f44372efbc0fba4b
%global ghostty_srcdirname ghostty-%{ghostty_commit}
%global srcdirname ghostling-%{commit}

Name:           ghostling-git
Version:        0.0.20260406git32c2dd5
Release:        %autorelease
Summary:        Minimal Ghostty VT terminal demo built from git snapshots

License:        MIT AND OFL-1.1
URL:            https://github.com/ghostty-org/ghostling
Source0:        https://codeload.github.com/ghostty-org/ghostling/tar.gz/%{commit}#/%{srcdirname}.tar.gz
Source1:        https://codeload.github.com/ghostty-org/ghostty/tar.gz/%{ghostty_commit}#/%{ghostty_srcdirname}.tar.gz
Source2:        https://ziglang.org/download/%{zig_version}/zig-x86_64-linux-%{zig_version}.tar.xz
Source3:        https://ziglang.org/download/%{zig_version}/zig-aarch64-linux-%{zig_version}.tar.xz
Source4:        ghostty-zig-cache-%{ghostty_commit}.tar.zst
Patch0:         0001-cmake-require-system-raylib-and-link-static-vt.patch

ExclusiveArch:  x86_64 aarch64

BuildRequires:  cmake
BuildRequires:  gcc
BuildRequires:  ninja-build
BuildRequires:  raylib-devel

%description
Ghostling is a minimal single-file terminal demo built on top of Ghostty's VT
engine. This snapshot package tracks upstream git while Ghostling is still
pre-release.

%prep
rm -rf "%{srcdirname}" "%{ghostty_srcdirname}"

tar -xzf %{SOURCE0}
srcroot="$(tar -tf %{SOURCE0} | head -1 | cut -d/ -f1)"
if [ "$srcroot" != "%{srcdirname}" ]; then
  mv "$srcroot" "%{srcdirname}"
fi

tar -xzf %{SOURCE1}
srcroot="$(tar -tf %{SOURCE1} | head -1 | cut -d/ -f1)"
if [ "$srcroot" != "%{ghostty_srcdirname}" ]; then
  mv "$srcroot" "%{ghostty_srcdirname}"
fi

pushd "%{ghostty_srcdirname}"
tar --zstd -xf %{SOURCE4}
popd

pushd "%{srcdirname}"
%autopatch -p1
popd

%build
cd "%{srcdirname}"

%ifarch x86_64
tar -xJf %{SOURCE2}
export PATH="$PWD/zig-x86_64-linux-%{zig_version}:$PATH"
%endif
%ifarch aarch64
tar -xJf %{SOURCE3}
export PATH="$PWD/zig-aarch64-linux-%{zig_version}:$PATH"
%endif

ghostty_flags="--system;%{_builddir}/%{ghostty_srcdirname}/vendor/p;-Dsimd=false"
cmake -S . -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DFETCHCONTENT_SOURCE_DIR_GHOSTTY="%{_builddir}/%{ghostty_srcdirname}" \
  -DGHOSTTY_ZIG_BUILD_FLAGS:STRING="$ghostty_flags"
cmake --build build

%install
install -Dpm0755 "%{srcdirname}/build/ghostling" "%{buildroot}%{_bindir}/ghostling"

%check
test -x "%{srcdirname}/build/ghostling"

%files
%license %{srcdirname}/LICENSE
%license %{srcdirname}/fonts/OFL.txt
%{_bindir}/ghostling

%changelog
%autochangelog
