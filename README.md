# North Desktop Template

Este pacote entrega a base pronta para iniciar um novo projeto usando o shell padronizado do North Desktop.

## Arquivos disponiveis

- `New-Project.bat`: inicia a geracao do projeto.
- `NorthDesktop.Template.zip`: pacote base usado na criacao do projeto.
- `README.md`: este guia rapido.

## Como usar

1. Se estiver online, rode `git pull` ou apenas execute `New-Project.bat`.
2. Execute `New-Project.bat`.
3. Informe o nome do projeto.
4. Informe a pasta de destino ou pressione Enter para usar a pasta atual.

## O que o New-Project.bat faz

1. Tenta atualizar o template com `git pull`.
2. Se o Git falhar ou estiver sem internet, segue com os arquivos locais.
3. Extrai o zip com a ultima versao disponivel na maquina.
4. Cria a pasta do projeto com o nome informado.
5. Ajusta nome tecnico, namespace, solution e restore inicial.

## Observacoes

- O script nao apaga mais o zip nem a si mesmo.
- Isso permite reutilizar o pacote mesmo offline.
- Para pegar a versao mais nova, basta executar o mesmo `New-Project.bat` novamente quando estiver online.

## Autor

- Marcus Vinicius Gaspar (**contato@marcusgaspar.com**)
