# Prompt para Desenvolvimento de Aplicativo Flutter: SD Maid SE

## Objetivo
Desenvolver um aplicativo móvel em Flutter para Android que replique as funcionalidades principais do SD Maid SE (System Cleaner), com foco em otimização de armazenamento, limpeza de arquivos desnecessários e gerenciamento de aplicativos. O aplicativo deve ser moderno, eficiente e seguir as melhores práticas de design e desempenho do Android.

## Funcionalidades Essenciais

### 1. CorpseFinder (Localizador de Cadáveres)
- **Descrição:** Identificar e remover arquivos e diretórios residuais de aplicativos desinstalados. Isso inclui dados em `/data/data`, `/Android/data`, `/Android/obb` e outros locais comuns onde aplicativos deixam rastros.
- **Implementação Flutter:** Necessitará de acesso a diretórios de armazenamento externo e interno. Pode envolver a leitura de listas de pacotes instalados e comparação com diretórios existentes.

### 2. AppCleaner (Limpador de Aplicativos)
- **Descrição:** Limpar caches de aplicativos, arquivos temporários e outros dados dispensáveis para liberar espaço. Deve oferecer diferentes métodos de limpeza, considerando as restrições do Android moderno.
- **Implementação Flutter:**
    - **Limpeza via Acessibilidade:** Implementar um serviço de acessibilidade para simular toques e navegar até as configurações de cada aplicativo para limpar o cache. Esta é uma solução mais lenta e pode ser inconsistente em diferentes dispositivos.
    - **Integração Shizuku/ADB:** Oferecer suporte à integração com Shizuku para realizar limpezas de cache mais rápidas e eficientes sem a necessidade de root, utilizando as APIs de depuração do Android.
    - **Limpeza com Root:** Para dispositivos rooteados, permitir a execução de comandos de shell para acesso direto e limpeza de caches e dados de aplicativos.
    - **Filtros:** Permitir que o usuário configure filtros para tipos específicos de arquivos a serem limpos (ex: logs, miniaturas, arquivos temporários).

### 3. SystemCleaner (Limpador de Sistema)
- **Descrição:** Deletar arquivos genéricos e temporários do sistema, como arquivos de log, arquivos temporários de download, pastas vazias e outros itens desnecessários.
- **Implementação Flutter:** Permitir a criação de filtros personalizados baseados em padrões de nome de arquivo, extensão e localização para identificar e remover arquivos do sistema.

### 4. Scheduler (Agendador)
- **Descrição:** Agendar tarefas de limpeza automática em intervalos definidos pelo usuário (diariamente, semanalmente, etc.).
- **Implementação Flutter:** Utilizar `WorkManager` (Android) ou `flutter_background_service` para executar tarefas em segundo plano de forma confiável e eficiente.

### 5. AppControl (Controle de Aplicativos)
- **Descrição:** Fornecer uma interface para visualizar, congelar (desativar), redefinir dados ou desinstalar aplicativos instalados no dispositivo.
- **Implementação Flutter:** Requer acesso às informações dos pacotes instalados. Ações como desinstalar ou congelar podem precisar de permissões elevadas ou interação com APIs do sistema.

### 6. StorageAnalyzer (Analisador de Armazenamento)
- **Descrição:** Oferecer uma visão detalhada do uso do armazenamento, mostrando quais arquivos e pastas estão ocupando mais espaço, categorizados por tipo (imagens, vídeos, documentos, apps, etc.).
- **Implementação Flutter:** Escanear o sistema de arquivos e apresentar os dados de forma visualmente atraente (ex: gráficos de pizza, barras) para facilitar a identificação de grandes consumidores de espaço.

### 7. Deduplicator (Deduplicador)
- **Descrição:** Encontrar e remover arquivos duplicados (fotos, vídeos, documentos) para liberar espaço.
- **Implementação Flutter:** Implementar algoritmos para comparar arquivos (ex: hash MD5) e apresentar os duplicados ao usuário para revisão e exclusão.

### 8. Media Squeeze (Compressão de Mídia)
- **Descrição:** Comprimir imagens para reduzir o tamanho do arquivo sem perda perceptível de qualidade.
- **Implementação Flutter:** Utilizar bibliotecas de processamento de imagem para re-codificar e comprimir imagens selecionadas pelo usuário.

### 9. Swiper (Deslizar para Deletar)
- **Descrição:** Uma interface de usuário intuitiva baseada em gestos para revisar e deletar arquivos ou fotos rapidamente.
- **Implementação Flutter:** Desenvolver um componente de UI que permita ao usuário deslizar para a esquerda/direita para descartar ou deletar itens, similar a interfaces de galeria ou gerenciadores de tarefas.

## Considerações Técnicas e de Permissões

- **Permissões Android:** O aplicativo exigirá diversas permissões, incluindo `MANAGE_EXTERNAL_STORAGE` (para Android 11+), `QUERY_ALL_PACKAGES`, `REQUEST_DELETE_PACKAGES`, `BIND_ACCESSIBILITY_SERVICE` e potencialmente `WRITE_SETTINGS`.
- **Restrições do Android:** É crucial entender as restrições de acesso a dados de outros aplicativos impostas pelas versões mais recentes do Android. As soluções para AppCleaner (Acessibilidade, Shizuku, Root) são exemplos de como contornar essas limitações.
- **UI/UX:** O design deve ser limpo, moderno e intuitivo, seguindo as diretrizes do Material Design. A experiência do usuário deve ser fluida e responsiva.
- **Internacionalização:** Suporte a múltiplos idiomas (pelo menos Português e Inglês).
- **Performance:** O aplicativo deve ser otimizado para não consumir excessivamente bateria ou recursos do sistema durante as operações de varredura e limpeza.
- **Segurança:** Garantir que o aplicativo não delete arquivos importantes por engano. Implementar um sistema de exclusões e níveis de risco para itens a serem deletados.

## Pacotes Flutter Sugeridos
- `path_provider`: Para acessar diretórios comuns do sistema de arquivos.
- `permission_handler`: Para gerenciar permissões do Android.
- `device_info_plus`: Para obter informações sobre o dispositivo e a versão do Android.
- `flutter_background_service` ou `workmanager`: Para execução de tarefas em segundo plano.
- `image_picker` e `image`: Para seleção e processamento de imagens (Media Squeeze).
- `charts_flutter` ou `fl_chart`: Para visualização de dados no StorageAnalyzer.
- `crypto`: Para gerar hashes de arquivos no Deduplicator.
- `flutter_local_notifications`: Para notificações de agendamento.

## Estrutura do Projeto
O projeto deve seguir uma arquitetura limpa (ex: Clean Architecture, BLoC/Cubit, Provider) para facilitar a manutenção e escalabilidade.

## Próximos Passos
Após a criação do projeto Flutter, será necessário detalhar a implementação de cada funcionalidade, focando nas APIs nativas do Android e nas bibliotecas Flutter que podem auxiliar na replicação do comportamento do SD Maid SE.
