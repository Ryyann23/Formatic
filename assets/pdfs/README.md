# Como adicionar PDFs à biblioteca

## Instruções

1. **Baixe os PDFs** que você deseja adicionar à biblioteca
2. **Coloque os arquivos PDF** nesta pasta (`assets/pdfs/`)
3. **Renomeie os arquivos** com nomes significativos (sem espaços, use underscore `_` ou hífen `-`)
   - Exemplo: `calculo1.pdf`, `fisica_mecanica.pdf`, `quimica_organica.pdf`

## Exemplos de fontes para PDFs gratuitos:

### Livros acadêmicos gratuitos:
- **Project Gutenberg** (https://www.gutenberg.org/) - Livros de domínio público
- **Open Library** (https://openlibrary.org/) - Biblioteca digital aberta
- **MIT OpenCourseWare** (https://ocw.mit.edu/) - Materiais de cursos do MIT
- **Khan Academy** (https://www.khanacademy.org/) - Materiais educacionais
- **arXiv** (https://arxiv.org/) - Artigos científicos
- **Domínio Público** (http://www.dominiopublico.gov.br/) - Portal brasileiro

### PDFs exemplo incluídos no BookService:

Os seguintes livros estão configurados no sistema (você precisa adicionar os PDFs correspondentes):

1. `calculo1.pdf` - Cálculo Volume I
2. `fisica1.pdf` - Física I - Mecânica  
3. `quimica_organica.pdf` - Química Orgânica
4. `biologia_celular.pdf` - Biologia Celular
5. `historia_brasil.pdf` - História do Brasil
6. `filosofia_intro.pdf` - Introdução à Filosofia
7. `Medicina.pdf` - Medicina Geral
8. `psicologia_dev.pdf` - Psicologia do Desenvolvimento
9. `algoritmos.pdf` - Algoritmos e Estruturas de Dados
10. `exercicios_calculo.pdf` - Exercícios de Cálculo
11. `dir_constitucional.pdf` - Direito Constitucional
12. `administracao.pdf` - Administração Geral
13. `eng_software.pdf` - Engenharia de Software
14. `resumo_fisica_moderna.pdf` - Resumo de Física Moderna

## Notas importantes:

- ⚠️ Certifique-se de ter os **direitos autorais** ou que os livros sejam de **domínio público**
- O primeiro livro da lista usa uma URL externa como exemplo (não precisa estar nesta pasta)
- Depois de adicionar os PDFs, execute `flutter pub get` e reinicie o app
- Os arquivos devem estar em formato PDF válido
- Tamanho recomendado: até 50MB por arquivo

## Usando URLs de PDFs online:

Você também pode usar PDFs hospedados online. No arquivo `book_service.dart`, basta colocar a URL completa no campo `pdfPath`:

```dart
pdfPath: 'https://example.com/path/to/book.pdf',
```

Isso permite usar PDFs sem ocupar espaço no app!
