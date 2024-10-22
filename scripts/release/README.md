# Guia de Release para Projeto

Este documento descreve o fluxo de release adotado para os projetos, utilizando o Git Flow para gerenciar o desenvolvimento e lançamento de novas versões, e o Commitizen para padronização de mensagens de commit.

### Automação com Shell Script

Para simplificar e automatizar o processo de release, foi criado um shell script que executa todos os passos necessários. Basta executar o script para realizar o release de forma automática. O script está disponível neste mesmo diretório: [`release.sh`](./release.sh) para Linux e [`release.ps1`](./release.ps1) para Windows.

### Passos para Lançamento de uma Nova Versão

Caso prefira realizar o processo manualmente, siga os passos abaixo:

1. **Verificar a branch develop:**
   Certifique-se de estar na branch `develop` antes de iniciar o processo de lançamento:
   ```bash
   git checkout develop
   ```

2. **Determinar a nova versão usando Commitizen:**
   Utilize o comando `cz bump --dry-run` para determinar a próxima versão do projeto:
   ```bash
   cz bump --dry-run
   ```
   Isso retornará informações como:
   ```
   bump: version 0.12.0 → 0.13.0
   tag to create: 0.13.0
   increment detected: MINOR
   ```
   Observe o número `0.13.0`, que é a nova versão a ser criada.

3. **Iniciar uma nova release com Git Flow:**
   Inicie uma nova release com o número de versão obtido no passo anterior:
   ```bash
   git flow release start 0.13.0
   ```

4. **Determinar e atualizar a nova versão usando Commitizen:** Utilize o comando `cz bump` para determinar e atualizar a próxima versão do projeto:
   > **Dica:** Para atualizar a versão nos arquivos externos (como `package.json` e `README.md`), verifique se a versão especificada no arquivo `.cz.toml` é a mesma que a versão atual nos arquivos. Isso garante que a atualização seja precisa e consistente. 
   ```bash
   cz bump
   ```
   Isso atualiza automaticamente o número da versão no projeto e cria uma tag para essa versão.

5. **Atualizar o Changelog com Commitizen:**
   Utilize o Commitizen para adicionar as mudanças ao changelog:
   ```bash
   cz changelog --incremental
   ```
   Alternativamente, você pode usar `cz ch --incremental`.

6. **Adicionar o CHANGELOG.md ao Git:**
   Adicione o arquivo `CHANGELOG.md` ao controle de versão:
   ```bash
   git add CHANGELOG.md
   ```

7. **Comitar o changelog atualizado:**
   Faça o commit do changelog atualizado:
   ```bash
   git commit -m "docs(changelog): updating changelog with changes of current release

   auto generating changelog incrementally using commitizen"
   ```

8. **Criar um changelog temporário para finalizar a release:**
   Gere um changelog temporário usando o Commitizen para finalizar a release:

   #### Para Linux:

   ```bash
   cz ch 0.13.0 --dry-run | sed -e 's/^## //' -e 's/^### //' -e 's/^-\(.*\)$/\t- \1/' > tag-message.txt
   ```

   #### Para Windows:

   ```powershell
   cz ch 0.13.0 --dry-run |
      ForEach-Object { $_ -replace '^(#+)\s*', '' -replace '^-\s*', "`t - " } |
      Out-File -FilePath tag-message.txt -Encoding utf8
   ```

9. **Deletar a tag criada pelo Commitizen:**
   Delete a tag criada pelo Commitizen, para que o git flow possa criar a tag de forma correta:
   ```bash
   git tag -d 0.13.0
   ```

10. **Configurar a variável de ambiente GIT_MERGE_AUTOEDIT:**
      Configure a variável de ambiente `GIT_MERGE_AUTOEDIT` para `no` a fim de prevenir mensagens de merge:

      #### Para Linux:

      ```bash
      export GIT_MERGE_AUTOEDIT=no
      ```

      #### Para Windows:

      ```powershell
      $env:GIT_MERGE_AUTOEDIT = "no"
      ```

11. **Finalizar a release com Git Flow:**
    Finalize a release utilizando o número de versão determinado, permitindo a criação da tag:
    ```bash
    git flow release finish -f tag-message.txt 0.13.0
    ```

12. **Desconfigurar a variável de ambiente GIT_MERGE_AUTOEDIT:**
      Desconfigure a variável de ambiente `GIT_MERGE_AUTOEDIT`:

      #### Para Linux:

      ```bash
      unset GIT_MERGE_AUTOEDIT
      ```

      #### Para Windows:

      ```powershell
      $env:GIT_MERGE_AUTOEDIT = ""
      ```

13. **Limpar o changelog temporário:**
      Remova o arquivo temporário `tag-message.txt`:

      #### Para Linux:

      ```bash
      rm tag-message.txt
      ```

      #### Para Windows:

      ```powershell
      Remove-Item tag-message.txt
      ```

Seguindo esses passos, você poderá realizar o release de uma nova versão do projeto manualmente.