# Home desktop

- `AppBreakpoints.desktop` decide o layout pela largura da janela; o espaço útil dos carrosséis vem de `LayoutBuilder`.
- A sidebar ocupa toda a altura do shell. A Home oculta sua logo no desktop, limita o conteúdo a 1360 px e soma 12 px às margens existentes de 20 px.
- `ContentCarousel` distribui pôsteres de 160–224 px em 3–7 posições. `RankedContentCarousel` usa pôsteres de 144 × 216 px em 2–4 posições, mantendo ranking e metadados.
- `CarouselViewport` compartilha clipping, setas acessíveis e scroll por toque, mouse e trackpad. Seu controller persiste ao redimensionar e acompanha o ciclo de vida da seção; o keep-alive existente mantém as seções ao trocar de página.
- As medidas e interações mobile, filtros, Hero e carregamento continuam nos componentes originais. Os controles de filtro já limitam sua largura a 336 px.

Validação: testes de widgets nas larguras 390, 768, 1024, 1366 e 1920 px, nos dois temas, além dos testes existentes de Home, recomendações, Hero, scroll e navegação.
