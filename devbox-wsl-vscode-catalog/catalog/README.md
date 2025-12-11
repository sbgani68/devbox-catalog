
# Dev Box Team Customization: Windows 11 25H2 + WSL + VS Code

This catalog contains a team customization that layers **WSL (Ubuntu)** and **Visual Studio Code**
on top of the Microsoft managed image:

```
microsoftwindowsdesktop_windows-ent-cpc_win11-25h2-ent-cpc-m365
```

## Structure
```
catalog/
├── image-definitions/
│   └── win11-25h2-wsl-vscode/
│       ├── imagedefinition.yaml
│       └── scripts/
│           ├── install-wsl.ps1
│           └── install-vscode.ps1
└── tasks/
    └── powershell/
        └── task.yaml
```

## How to use
1. **Attach this repo as a Catalog** to your Dev Center Project (Azure Portal → Dev Center → Project → Catalogs → Add catalog).
2. **Sync catalog items** for the project.
3. **Create/Update a Dev Box Pool** and set Image source = **Catalog**.
4. Choose the image definition: `win11-25h2-wsl-vscode`.
5. Provision new Dev Boxes from the pool. WSL and VS Code will be installed automatically during provisioning.

## Notes
- Enabling WSL features requires a restart; Dev Box handles restarts during provisioning.
- You can change the distro by editing `install-wsl.ps1` (use `wsl --list --online`).
- If your scripts need access to private resources, set `buildProperties.networkConnection` in `imagedefinition.yaml`.
