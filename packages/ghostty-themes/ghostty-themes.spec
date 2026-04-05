Name:           ghostty-themes
Version:        20260323
Release:        %autorelease -b 1
Summary:        Optional color themes for Ghostty

License:        MIT
URL:            https://github.com/mbadolato/iTerm2-Color-Schemes
Source0:        https://deps.files.ghostty.org/ghostty-themes-release-20260323-152405-a2c7b60.tgz#/%{name}-%{version}.tar.gz
Source1:        https://raw.githubusercontent.com/mbadolato/iTerm2-Color-Schemes/master/LICENSE#/%{name}-LICENSE

BuildArch:      noarch
Requires:       ghostty

%description
Optional Ghostty theme files installed under %%{_datadir}/ghostty/themes.
The shipped theme archive is the snapshot currently consumed by upstream
Ghostty builds.

%prep
rm -rf themes-root
mkdir themes-root
tar -xzf %{SOURCE0} -C themes-root
cp %{SOURCE1} LICENSE

%build
: # no build step for data-only package

%check
: # no test step for data-only package

%install
mkdir -p "%{buildroot}%{_datadir}/ghostty/themes"
cp -a themes-root/ghostty/. "%{buildroot}%{_datadir}/ghostty/themes/"

%files
%license LICENSE
%dir %{_datadir}/ghostty/themes
%{_datadir}/ghostty/themes/*

%changelog
%autochangelog
