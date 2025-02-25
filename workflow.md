## Terraform com CICD 

Para automatizar o processo de deploy do seu código Terraform usando CI/CD no GitHub, você pode seguir as etapas abaixo. Vamos usar o GitHub Actions, que é uma ferramenta integrada ao GitHub, para configurar os pipelines.

### Passos:

#### 1. **Criar um arquivo de workflow do GitHub Actions**
No repositório GitHub, você precisará criar um arquivo de workflow do GitHub Actions para automatizar o processo de deploy. Esse arquivo vai controlar quando o Terraform deve ser executado (como em pushes ou PRs).

- Crie o diretório `.github/workflows` na raiz do seu projeto, se ele não existir.
- Dentro de `.github/workflows`, crie um arquivo como `terraform.yml`.

A estrutura ficará assim:

```bash
.github/
└── workflows/
    └── terraform.yml
```

#### 2. **Configurar o arquivo `terraform.yml`**

Aqui está um exemplo básico de como configurar um workflow de CI/CD para o Terraform no GitHub Actions.

```yaml
name: Terraform CI/CD

on:
  push:
    branches:
      - main  # Alvo da branch para disparar a pipeline
  pull_request:
    branches:
      - main

jobs:
  terraform:
    name: Aplicar Terraform
    runs-on: ubuntu-latest

    steps:
      - name: Checkout do repositório
        uses: actions/checkout@v4

      - name: Configuração do AWS CLI
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: 'us-east-1'

      - name: Instalar o Terraform
        run: |
          sudo apt-get update && sudo apt-get install -y wget unzip
          wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
          unzip terraform_1.5.0_linux_amd64.zip
          sudo mv terraform /usr/local/bin/

      - name: Inicializar o Terraform
        run: cd terraform && terraform init

      - name: Validar configuração do Terraform
        run: cd terraform && terraform validate

      - name: Aplicar o Terraform
        run: cd terraform && terraform apply -auto-approve -var-file=terraform/env/${{ github.event_name }}.tfvars

      - name: Exibir o output do Terraform
        run: terraform output
```

#### 3. **Explicando as etapas do workflow**

- **Checkout do repositório**: A primeira etapa é fazer checkout do repositório para garantir que o GitHub Actions tenha acesso aos arquivos.
- **Configuração do AWS CLI**: Aqui, usamos a ação `aws-actions/configure-aws-credentials` para configurar as credenciais da AWS (serão armazenadas de maneira segura em Secrets no GitHub).
- **Instalar o Terraform**: Instalamos o Terraform no runner, já que ele não vem pré-instalado.
- **Inicializar o Terraform**: O `terraform init` prepara o diretório de trabalho e baixa os módulos necessários.
- **Validar o Terraform**: O `terraform validate` garante que a sintaxe do seu código esteja correta.
- **Aplicar o Terraform**: O `terraform apply` executa a criação ou modificação dos recursos na AWS com base no código e nos arquivos `.tfvars` de configuração.
- **Exibir o output do Terraform**: Por fim, você pode visualizar os outputs do Terraform, como os endereços IP de recursos criados.

#### 4. **Configurar o GitHub Secrets**

Para garantir que as credenciais da AWS estejam seguras, você deve configurá-las no GitHub Secrets.

- Vá até seu repositório no GitHub.
- Na barra superior, clique em **Settings**.
- No menu à esquerda, clique em **Secrets** e depois em **New repository secret**.
- Crie dois secrets chamados:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`

Adicione as credenciais da AWS que o GitHub Actions usará para aplicar o Terraform.

#### 5. **Testar o Workflow**

Agora que o arquivo do workflow está configurado e os secrets estão no lugar, faça um push para a branch `main` ou crie um pull request. O GitHub Actions irá executar o pipeline e aplicar o Terraform automaticamente.

### Considerações adicionais

- **Variáveis de Ambiente**: Se você tiver múltiplos ambientes (como `dev`, `prod`, `staging`), você pode configurar diferentes arquivos `.tfvars` para cada ambiente. O exemplo acima faz isso de forma automática com base no tipo de evento (`push` ou `pull_request`).
  
- **State do Terraform**: Para evitar problemas com o estado (state) compartilhado entre diferentes execuções, recomendo usar o Amazon S3 com o DynamoDB para manter o estado do Terraform remoto e evitar o bloqueio do estado. Você pode configurar isso com o recurso `backend` do Terraform.

- **Workspaces**: Outra abordagem interessante para gerenciar diferentes ambientes é usar workspaces do Terraform. Isso pode ser útil se você deseja trabalhar com múltiplos ambientes no mesmo código Terraform sem a necessidade de múltiplos arquivos de configuração.

### Exemplo de configuração do backend (S3 + DynamoDB)

No seu `main.tf`, você pode configurar o backend remoto para o estado do Terraform:

```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state-bucket"
    key    = "terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "my-terraform-lock-table"
    encrypt = true
  }
}
```

Isso vai configurar o Terraform para armazenar o estado no S3 e usar o DynamoDB para evitar problemas de concorrência.

Agora seu pipeline estará pronto para ser executado a cada push ou pull request, garantindo a automação do processo de deploy da AWS com o Terraform via GitHub Actions!

Se precisar de mais ajuda em alguma dessas etapas, só avisar!



O trecho que você mencionou:

```bash
-var-file=terraform/env/${{ github.event_name }}.tfvars
```

utiliza a variável `${{ github.event_name }}`, que é uma variável especial fornecida pelo GitHub Actions. Vamos analisar detalhadamente:

### O que é `${{ github.event_name }}`?

Essa variável contém o tipo do evento que disparou o workflow no GitHub. Por exemplo:

- Se você fez um **push** para a branch principal, o valor será `push`.
- Se você criou um **pull request**, o valor será `pull_request`.
- Se você usou um **workflow_dispatch** (executar o workflow manualmente), o valor será `workflow_dispatch`.
  
Ou seja, `${{ github.event_name }}` basicamente vai pegar o tipo do evento e utilizá-lo no seu fluxo.

### Como isso é utilizado no seu código?

No trecho:

```bash
-var-file=terraform/env/${{ github.event_name }}.tfvars
```

A ideia é carregar o arquivo de variáveis (`.tfvars`) correspondente ao evento que disparou o workflow. Isso é útil para você aplicar diferentes configurações dependendo do ambiente ou do tipo de ação que ocorreu.

Por exemplo:

- Se o evento for um **push** para a branch principal, o arquivo de variáveis seria `terraform/env/push.tfvars`.
- Se o evento for um **pull_request**, o arquivo seria `terraform/env/pull_request.tfvars`.

Esse arquivo de variáveis (`.tfvars`) pode conter parâmetros diferentes para diferentes ambientes ou ações. Por exemplo:

- **`terraform/env/push.tfvars`** pode conter variáveis específicas para deploys automáticos após um push.
- **`terraform/env/pull_request.tfvars`** pode ter variáveis usadas em testes ou validações antes de um merge.

### Como funciona o `${{ github.event_name }}`?

O `${{ github.event_name }}` é uma das variáveis de contexto do GitHub Actions. O GitHub Actions fornece diversas variáveis de contexto que podem ser usadas para acessar informações sobre o workflow, o repositório, o commit, o evento e muito mais.

Essas variáveis são definidas automaticamente pelo GitHub e são acessadas no formato `${{ github.[nome_da_variável] }}`.

**Exemplos de variáveis do GitHub Actions:**

- `${{ github.event_name }}`: Tipo do evento que acionou o workflow (como `push`, `pull_request`).
- `${{ github.actor }}`: Usuário que iniciou o evento (por exemplo, o nome do usuário que fez o commit ou o PR).
- `${{ github.ref }}`: Ref que causou o evento (por exemplo, `refs/heads/main`).
- `${{ github.sha }}`: O hash do commit atual.

### Configuração do `.tfvars`

Para que o seu comando `terraform apply -var-file=terraform/env/${{ github.event_name }}.tfvars` funcione corretamente, você precisa garantir que o arquivo de variáveis esteja presente dentro da pasta `terraform/env/`, e que ele corresponda ao nome do evento. Isso é o que você tem que garantir manualmente ao criar esses arquivos de configuração:

#### Exemplo:

- Crie um arquivo de variáveis para `push`: `terraform/env/push.tfvars`.
- Crie um arquivo de variáveis para `pull_request`: `terraform/env/pull_request.tfvars`.

Esses arquivos podem ter variáveis específicas para cada tipo de ação. Exemplo:

```hcl
# terraform/env/push.tfvars
instance_type = "t2.micro"
region = "us-east-1"
```

```hcl
# terraform/env/pull_request.tfvars
instance_type = "t2.small"
region = "us-west-2"
```

Então, quando o evento for um `push`, o workflow vai buscar e aplicar as variáveis do arquivo `push.tfvars`. E se for um `pull_request`, ele aplicará as variáveis do arquivo `pull_request.tfvars`.

### Conclusão

- O `${{ github.event_name }}` é uma variável de contexto que representa o tipo de evento que disparou o workflow no GitHub.
- Ao usar essa variável, você pode condicionalmente aplicar configurações diferentes no Terraform dependendo do tipo de evento.
- O arquivo `.tfvars` é um arquivo de variáveis do Terraform, e você está usando `${{ github.event_name }}` para carregar diferentes arquivos de variáveis com base no evento.

Isso ajuda a configurar seu ambiente de forma dinâmica e flexível, dependendo do tipo de ação que está sendo executada no seu repositório.