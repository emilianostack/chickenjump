# Publicar o ChickenJump no itch.io

## 1. Gerar os pacotes

Clique com o botão direito em `exportar.ps1` e escolha "Executar com o PowerShell".
Os arquivos saem em `build/`:

- `ChickenJump-web.zip`
- `ChickenJump-windows.zip`

## 2. Criar a página no itch.io

Em Dashboard > Create new project:

- Kind of project: **HTML**
- Envie `ChickenJump-web.zip` e marque **This file will be played in the browser**
- Envie `ChickenJump-windows.zip` e marque a plataforma **Windows**
- Embed options:
  - Viewport: **480 x 800**
  - Marque **Mobile friendly**, com orientação **Portrait**
  - Marque o botão de tela cheia

Publique primeiro como **Draft** ou **Restricted** e teste no celular e no computador
antes de deixar **Public**.

