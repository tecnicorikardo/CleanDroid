# CleanDroid

Aplicativo Android em Flutter para limpeza e analise de arquivos acessiveis pelo Android.

## Estado atual

### FASE 1 - Motor de scan de arquivos

Implementado:

- Varredura real em diretorios permitidos pelo Android.
- Deteccao de arquivos `.tmp`.
- Deteccao de arquivos `.log`.
- Deteccao de arquivos vazios.
- Calculo de quantidade e tamanho total encontrados.
- Exibicao dos arquivos encontrados na tela principal.

O scanner nao usa dados ficticios, numeros aleatorios ou resultados simulados.

## Limitacoes conhecidas

- Em Android moderno, arquivos de outros aplicativos nao podem ser acessados livremente sem permissoes especiais, Shizuku, root ou fluxos via acessibilidade.
- Sem a permissao de gerenciamento amplo de arquivos, o app analisa apenas diretorios proprios e caches acessiveis.
- O acesso a `Download` depende da permissao `MANAGE_EXTERNAL_STORAGE` e das regras do dispositivo.

## Validacao

Comandos usados durante o desenvolvimento:

```powershell
flutter analyze
flutter test
flutter build apk --debug
```
