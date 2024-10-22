# Guia de Hotfix para Projeto

Este documento descreve o fluxo de hotfix adotado para os projetos, utilizando o Git Flow para gerenciar o desenvolvimento e lançamento de novas versões, e o Commitizen para padronização de mensagens de commit.

### Passos para Lançamento de uma Nova Correção Emergencial

Este guia detalha os passos necessários para realizar um lançamento de versão utilizando o Git Flow e o Commitizen, de acordo com o script automatizado.

#### Uso do Shell Script para Automatizar o Processo

Para simplificar e automatizar o processo de hotfix, foi criado um shell script que executa todos os passos necessários. O script está disponível neste mesmo diretório como [`hotfix.sh`](./hotfix.sh) para Linux e [`hotfix.ps1`](./hotfix.ps1) para Windows.

#### Iniciando um Hotfix

1. **Verificar a branch main:**
   Certifique-se de estar na branch `main` antes de iniciar o processo de lançamento:
   ```bash
   git checkout main
   ```

2. **Iniciar um novo hotfix com o Shell Script:**
   Execute o script com o argumento `start` para iniciar um novo hotfix:
   
   **Linux:**
   ```bash
   ./hotfix.sh start
   ```

   **Windows:**
   ```powershell
   .\hotfix.ps1 start
   ```

3. **Realizar alterações:**
   Faça as correções necessárias para corrigir o bug observado, e certifique-se de fazer **pelo menos um commit do tipo fix** dentro dessa branch, e **não fazer nenhum commit dos tipos feat ou com breaking changes**.

#### Finalizando um Hotfix

1. **Finalizar o hotfix com o Shell Script:**
   Execute o script com o argumento `finish` para finalizar o hotfix:

   **Linux:**
   ```bash
   ./hotfix.sh finish
   ```

   **Windows:**
   ```powershell
   .\hotfix.ps1 finish
   ```

#### Passos Manuais para Lançamento de uma Nova Correção Emergencial

Caso prefira seguir os passos manualmente, aqui estão os detalhes:

1. **Verificar a branch main:**
   Certifique-se de estar na branch `main` antes de iniciar o processo de lançamento:
   ```bash
   git checkout main
   ```

2. **Determinar a nova versão usando Commitizen:**
   Utilize o comando `cz version -p` para determinar a versão do projeto:
   ```bash
   cz version -p
   ```
   Vamos supor que o comando retornou `0.13.0`, que é a versão atual.

3. **Iniciar um novo hotfix com Git Flow:**
   Como se trata de um fix, **incremente uma unidade no PATCH**, e inicie um novo hotfix com o número de versão obtido no passo anterior:
   ```bash
   git flow hotfix start 0.13.1
   ```

4. **Realizar alterações:**
   Faça as correções necessárias para corrigir o bug observado, e certifique-se de fazer **pelo menos um commit do tipo fix** dentro dessa branch, e **não fazer nenhum commit dos tipos feat ou com breaking changes**.

5. **Determinar e atualizar a nova versão usando Commitizen:**
   Utilize o comando `cz bump` para determinar e atualizar a próxima versão do projeto:
   > **Dica:** Para atualizar a versão nos arquivos externos (como `package.json` e `README.md`), verifique se a versão especificada no arquivo `.cz.toml` é a mesma que a versão atual nos arquivos. Isso garante que a atualização seja precisa e consistente.
   ```bash
   cz bump
   ```
   Isso atualiza automaticamente o número da versão no projeto e cria uma tag para essa versão.

6. **Atualizar o Changelog com Commitizen:**
   Utilize o Commitizen para adicionar as mudanças ao changelog:
   ```bash
   cz changelog --incremental
   ```
   Alternativamente, você pode usar `cz ch --incremental`.

7. **Adicionar o CHANGELOG.md ao Git:**
   Adicione o arquivo `CHANGELOG.md` ao controle de versão:
   ```bash
   git add CHANGELOG.md
   ```

8. **Comitar o changelog atualizado:**
   Faça o commit do changelog atualizado:
   ```bash
   git commit -m "docs(changelog): updating changelog with changes of current bugfix

   auto generating changelog incrementally using commitizen"
   ```

9. **Criar um changelog temporário para finalizar o hotfix:**
   Gere um changelog temporário usando o Commitizen para finalizar o hotfix:

   **Linux:**
   ```bash
   cz ch 0.13.1 --dry-run | sed -e 's/^## //' -e 's/^### //' -e 's/^-\(.*\)$/\t- \1/' > tag-message.txt
   ```

   **Windows:**
   ```powershell
   cz ch 0.13.1 --dry-run |
      ForEach-Object { $_ -replace '^(#+)\s*', '' -replace '^-\s*', "`t - " } |
      Out-File -FilePath tag-message.txt -Encoding utf8
   ```

10. **Deletar a tag criada pelo Commitizen:**
    Delete a tag criada pelo Commitizen, para que o git flow possa criar a tag de forma correta:
    ```bash
    git tag -d 0.13.1
    ```

11. **Configurar a variável de ambiente GIT_MERGE_AUTOEDIT:**
    Configure a variável de ambiente `GIT_MERGE_AUTOEDIT` para `no` a fim de prevenir mensagens de merge:

    **Linux:**
    ```bash
    export GIT_MERGE_AUTOEDIT=no
    ```

    **Windows:**
    ```powershell
    $env:GIT_MERGE_AUTOEDIT = "no"
    ```

12. **Finalizar o hotfix com Git Flow:**
    Finalize o hotfix utilizando o número de versão determinado, permitindo a criação da tag:
    ```bash
    git flow hotfix finish -f tag-message.txt 0.13.1
    ```

13. **Desconfigurar a variável de ambiente GIT_MERGE_AUTOEDIT:**
    Desconfigure a variável de ambiente `GIT_MERGE_AUTOEDIT`:

    **Linux:**
    ```bash
    unset GIT_MERGE_AUTOEDIT
    ```

    **Windows:**
    ```powershell
    $env:GIT_MERGE_AUTOEDIT = ""
    ```

14. **Limpar o changelog temporário:**
    Remova o arquivo temporário `tag-message.txt`:

    **Linux:**
    ```bash
    rm tag-message.txt
    ```

    **Windows:**
    ```powershell
    Remove-Item tag-message.txt
    ```
