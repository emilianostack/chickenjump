# Publicar o ChickenJump no itch.io

## 1. Ativar o ranking (Talo)

1. Crie uma conta em https://trytalo.com e um jogo novo no painel.
2. Crie um leaderboard com:
   - internal name: `chicken-best` (precisa ser exatamente este)
   - ordem decrescente (maior pontuação primeiro)
   - entradas únicas por jogador, se a opção existir
3. Crie uma access key com os escopos `read:players`, `write:players`,
   `read:leaderboards` e `write:leaderboards`.
4. Cole a chave em `addons/talo/settings.cfg`, entre as aspas de `access_key=""`.

A chave vai dentro do jogo publicado, então dê a ela só esses quatro escopos.
Não coloque esse arquivo em repositório público.

## 2. Gerar os pacotes

Clique com o botão direito em `exportar.ps1` e escolha "Executar com o PowerShell".
Os arquivos saem em `build/`:

- `ChickenJump-web.zip`
- `ChickenJump-windows.zip`

## 3. Criar a página no itch.io

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

## 4. Conferir depois de ativar o ranking

- Jogue, escolha um nome e veja se a pontuação aparece na lista.
- Confira se a posição está certa (1º lugar aparece como `1.`).
- Remova pontuações falsas ou nomes ofensivos pelo painel da Talo.

## Dados dos jogadores

O jogo envia ao serviço Talo o nome escolhido, a pontuação e um ID aleatório gerado
no aparelho. Vale avisar isso na página do jogo.
