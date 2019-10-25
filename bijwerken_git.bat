@echo off
echo ... alle bestanden in de folder verwerken ...
git add .
echo.

echo ... status ophalen ...
git status
echo.

echo ... wijzigingen committen ...
git commit -m "nieuwe versie"
echo.

echo ... wijzigingen verzenden ...
git push origin master
echo.

echo ... klaar!
echo.

