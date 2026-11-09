; Les Mondes de Travers : l'installateur Windows (Inno Setup 6.7 ou plus récent).
; Un seul script pour les deux installateurs, choisis à la compilation :
;   ISCC /DVariante=PC /DVersion=124 /DExeSource=chemin\vers\le.exe les_mondes_de_travers.iss
;   ISCC /DVariante=VR /DVersion=124 /DExeSource=chemin\vers\le.exe les_mondes_de_travers.iss
; Les deux s'installent dans le même dossier et ont chacun leur raccourci et leur désinstallation.
; Les images (fond_*.png, petite_*.png) viennent de tools/generate_installateur.py.

#ifndef Variante
  #define Variante "PC"
#endif
#ifndef Version
  #define Version "0"
#endif
#ifndef ExeSource
  #error Il faut donner /DExeSource=chemin du jeu exporté
#endif

#define Jeu "Les Mondes de Travers"
#if Variante == "VR"
  #define Nom Jeu + " VR"
  #define Exe Jeu + " VR.exe"
  #define Id "{{6F1B2D84-3C1E-4F8A-9B57-2E4C7A91D0B3}"
  #define Quoi "la version casque (Meta Quest 3 par Link ou Air Link, ou SteamVR)"
#else
  #define Nom Jeu
  #define Exe Jeu + ".exe"
  #define Id "{{A3D95E21-7B04-4C6F-8E12-5F9B0C6D4A78}"
  #define Quoi "la version écran (clavier, souris ou manette)"
#endif

[Setup]
AppId={#Id}
AppName={#Nom}
AppVersion={#Version}
AppVerName={#Nom} V{#Version}
AppPublisher=janintibo-art
AppPublisherURL=https://github.com/janintibo-art/ile-manga
AppSupportURL=https://github.com/janintibo-art/ile-manga
VersionInfoVersion={#Version}.0.0.0
VersionInfoDescription=Installation de {#Nom}
DefaultDirName={autopf}\{#Jeu}
DisableDirPage=no
DisableProgramGroupPage=yes
DisableWelcomePage=no
DisableReadyPage=no
UsePreviousAppDir=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputBaseFilename={#StringChange(Nom, " ", "_")}_Installation_v{#Version}
SetupIconFile=..\..\www\assets\textures\ui\les_mondes_de_travers_icon.ico
UninstallDisplayIcon={app}\{#Exe}
UninstallDisplayName={#Nom}
; Le jeu est déjà fait de fichiers compressés (textures, sons) : une compression rapide suffit.
Compression=lzma2/fast
SolidCompression=no
LZMANumBlockThreads=4
; La présentation : thème sombre, l'image du jeu en fond de toutes les pages.
WizardStyle=modern dark includetitlebar
WizardBackColor=#090d1c
WizardBackImageFile=fond_596.png,fond_796.png,fond_994.png,fond_1272.png,fond_1630.png
WizardBackImageOpacity=255
WizardImageFile=
WizardSmallImageFile=petite_58.png,petite_73.png,petite_87.png,petite_116.png,petite_145.png

[Languages]
Name: "fr"; MessagesFile: "compiler:Languages\French.isl"

[Messages]
fr.WelcomeLabel1=Bienvenue dans%n{#Nom}
fr.WelcomeLabel2=Cet assistant va installer {#Quoi} des Mondes de Travers, V{#Version}, sur votre ordinateur.%n%nVos sauvegardes sont gardées : elles sont communes à toutes les versions, écran et VR.%n%nCliquez sur Suivant pour continuer.
fr.FinishedHeadingLabel=Les Mondes de Travers%nsont prêts
fr.FinishedLabel={#Nom} est installé. Bonne aventure !

[Tasks]
Name: "bureau"; Description: "Créer une icône sur le Bureau"; GroupDescription: "Icônes supplémentaires :"

[Files]
Source: "{#ExeSource}"; DestDir: "{app}"; DestName: "{#Exe}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#Nom}"; Filename: "{app}\{#Exe}"; WorkingDir: "{app}"
Name: "{autodesktop}\{#Nom}"; Filename: "{app}\{#Exe}"; WorkingDir: "{app}"; Tasks: bureau

[Run]
Filename: "{app}\{#Exe}"; Description: "Lancer {#Nom}"; WorkingDir: "{app}"; Flags: nowait postinstall skipifsilent
