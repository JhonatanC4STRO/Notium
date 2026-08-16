const githubUrl = "https://github.com/JhonatanC4STRO/Notium";
const apkDownloadUrl = `${githubUrl}/releases/latest/download/notium-v1.0.0.apk`;
const onlineDemoUrl = "https://appetize.io/app/b_pcpdwcomrd4rfbtsdsstcijipi";
const apiHealthUrl = "https://api.notium.shona.lat/v1/health";

const features = [
  {
    number: "01",
    title: "Funciona sin señal",
    text: "Crear, editar, buscar y adjuntar archivos sigue disponible incluso en modo avión.",
  },
  {
    number: "02",
    title: "Datos cifrados",
    text: "SQLCipher protege la base local y Android Keystore resguarda las credenciales.",
  },
  {
    number: "03",
    title: "Sincronización confiable",
    text: "Push, pull, reintentos e idempotencia mantienen cada dispositivo al día.",
  },
  {
    number: "04",
    title: "Conflictos con historia",
    text: "Last-Write-Wins resuelve cambios simultáneos sin borrar la trazabilidad del valor descartado.",
  },
];

const stackDecisions = [
  {
    layer: "Cliente multiplataforma",
    technology: "Flutter + Dart",
    reason: "Un solo código base entrega Android hoy y deja abierta la evolución a iOS, web y escritorio.",
    tradeoff: "Evita mantener implementaciones nativas separadas con un equipo de una persona.",
  },
  {
    layer: "Estado y dependencias",
    technology: "Riverpod",
    reason: "Conecta streams de la base local con la interfaz mediante estado reactivo, tipado y fácil de probar.",
    tradeoff: "Menos boilerplate que BLoC y mejor separación de responsabilidades que GetX.",
  },
  {
    layer: "Persistencia local",
    technology: "Drift + SQLCipher",
    reason: "SQLite relacional, consultas validadas, migraciones y streams; SQLCipher cifra toda la base en reposo.",
    tradeoff: "Se eligió sobre almacenes NoSQL porque notas, adjuntos e historial tienen relaciones reales.",
  },
  {
    layer: "Trabajo en segundo plano",
    technology: "WorkManager",
    reason: "Programa sincronizaciones con restricción de red y sobrevive al cierre del proceso Android.",
    tradeoff: "Un timer o servicio en foreground consumiría más batería y dependería de que la app siga abierta.",
  },
  {
    layer: "Transporte",
    technology: "Dio + REST",
    reason: "Interceptores JWT, reintentos, cancelación, cargas multipart y control explícito del protocolo push/pull.",
    tradeoff: "Mantiene el cliente HTTP pequeño sin añadir generación de código innecesaria.",
  },
  {
    layer: "Autoridad de sincronización",
    technology: "Node.js + Express",
    reason: "Una API liviana concentra autenticación, idempotencia y resolución de conflictos.",
    tradeoff: "Menor costo operativo que un framework pesado para el volumen y alcance actuales.",
  },
  {
    layer: "Persistencia remota",
    technology: "PostgreSQL + Docker",
    reason: "Replica el modelo relacional del cliente y consolida versiones, historial y operaciones procesadas.",
    tradeoff: "Docker hace reproducible el despliegue de API y base de datos en el VPS.",
  },
];

const syncStates = [
  { state: "PENDING", title: "Pendiente", text: "El cambio ya está guardado localmente y espera conectividad." },
  { state: "SYNCED", title: "Sincronizado", text: "El servidor confirmó la operación y devolvió su versión autoritativa." },
  { state: "CONFLICT", title: "Conflicto", text: "Dos dispositivos editaron el mismo registro y el servidor debe resolver." },
  { state: "ERROR", title: "Requiere atención", text: "La validación falló; el dato local permanece disponible para corregirlo." },
];

export default function Home() {
  return (
    <main>
      <nav className="nav shell" aria-label="Navegación principal">
        <a className="brand" href="#inicio" aria-label="Notium, volver al inicio">
          <span className="brand-mark">N</span>
          <span>NOTIUM</span>
        </a>
        <div className="nav-links">
          <a href="#arquitectura">Arquitectura</a>
          <a href="#sincronizacion">Sincronización</a>
          <a href="#tecnologia">Tecnología</a>
          <a href={githubUrl} target="_blank" rel="noreferrer">
            GitHub ↗
          </a>
        </div>
      </nav>

      <section className="hero shell" id="inicio">
        <div className="hero-copy">
          <p className="eyebrow"><span /> Android · Offline-first</p>
          <h1>
            Tus notas no
            <br /> deberían esperar
            <br /> <em>por la red.</em>
          </h1>
          <p className="hero-lead">
            Un caso de estudio de arquitectura offline-first: cómo una app escribe,
            cifra y consulta localmente, y luego hace converger varios dispositivos
            sin bloquear al usuario.
          </p>
          <div className="hero-actions">
            <a className="button button-primary" href={onlineDemoUrl} target="_blank" rel="noreferrer">
              Probar en línea <span>↗</span>
            </a>
            <a className="button button-ghost" href={apkDownloadUrl}>
              Descargar APK <span>↓</span>
            </a>
          </div>
          <div className="hero-proof" aria-label="Resumen técnico">
            <div><strong>API 24+</strong><span>Android 7 o superior</span></div>
            <div><strong>100% offline</strong><span>Operación local continua</span></div>
            <div><strong>Open source</strong><span>Arquitectura documentada</span></div>
          </div>
        </div>

        <div className="hero-visual" aria-label="Vista conceptual de la aplicación Notium">
          <div className="orbit orbit-one" />
          <div className="orbit orbit-two" />
          <div className="sync-chip"><i /> Sincronizado</div>
          <div className="offline-chip">Modo offline</div>
          <div className="phone-shadow" />
          <div className="phone">
            <div className="phone-speaker" />
            <div className="phone-screen">
              <div className="phone-status"><span>9:41</span><span>● ◒</span></div>
              <div className="app-header">
                <div><small>BUEN DÍA</small><strong>Mis notas</strong></div>
                <span className="avatar">JC</span>
              </div>
              <div className="search">⌕&nbsp;&nbsp; Buscar en tus notas</div>
              <div className="note-card featured-note">
                <div className="note-top"><span className="note-tag cyan">PROYECTO</span><span>•••</span></div>
                <h3>Arquitectura offline-first</h3>
                <p>La interfaz siempre consulta la base local. La red llega después.</p>
                <footer><span>Hoy, 9:24</span><span className="synced-dot">✓</span></footer>
              </div>
              <div className="note-card">
                <div className="note-top"><span className="note-tag blue">IDEAS</span><span>•••</span></div>
                <h3>Próxima iteración</h3>
                <p>Probar el flujo entre dos dispositivos...</p>
                <footer><span>Ayer</span><span className="pending-dot">↻</span></footer>
              </div>
              <button className="fab" aria-label="Crear una nota" tabIndex={-1}>＋</button>
              <div className="phone-nav"><span className="active">▤<small>Notas</small></span><span>↻<small>Sync</small></span><span>◷<small>Historial</small></span></div>
            </div>
          </div>
        </div>
      </section>

      <div className="ticker" aria-hidden="true">
        <div>OFFLINE-FIRST <span>✦</span> CIFRADO LOCAL <span>✦</span> SINCRONIZACIÓN AUTOMÁTICA <span>✦</span> HISTORIAL AUDITABLE <span>✦</span></div>
      </div>

      <section className="statement shell section-pad">
        <p className="section-kicker">El problema</p>
        <div className="statement-grid">
          <h2>La conectividad es una variable, no un requisito.</h2>
          <div>
            <p>
              Muchas aplicaciones móviles dejan de ser útiles cuando la red falla.
              Notium invierte esa dependencia: cada acción se confirma localmente en
              milisegundos y la sincronización ocurre cuando es posible.
            </p>
            <p className="statement-note">Diseñada para trabajo de campo, movilidad y conexiones inestables.</p>
          </div>
        </div>
      </section>

      <section className="features shell" aria-labelledby="features-title">
        <div className="section-heading">
          <p className="section-kicker">Capacidades</p>
          <h2 id="features-title">Hecha para seguir trabajando.</h2>
        </div>
        <div className="feature-grid">
          {features.map((feature) => (
            <article className="feature-card" key={feature.number}>
              <span className="feature-number">{feature.number}</span>
              <div className="feature-icon" aria-hidden="true">{feature.number === "01" ? "⌁" : feature.number === "02" ? "◇" : feature.number === "03" ? "↻" : "◷"}</div>
              <h3>{feature.title}</h3>
              <p>{feature.text}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="architecture section-pad" id="arquitectura">
        <div className="shell">
          <div className="architecture-intro">
            <div>
              <p className="section-kicker light">Arquitectura</p>
              <h2>Local primero.<br />Red después.</h2>
            </div>
            <p>
              La base cifrada es la única fuente de verdad para la interfaz. Un
              coordinador independiente mueve cambios entre el dispositivo y el
              servidor sin bloquear al usuario.
            </p>
          </div>

          <div className="architecture-board" role="img" aria-label="Flujo de arquitectura: aplicación Flutter, base local cifrada, coordinador de sincronización, API Node y PostgreSQL">
            <div className="arch-node arch-device">
              <small>DISPOSITIVO ANDROID</small>
              <strong>Flutter + Riverpod</strong>
              <span>Interfaz reactiva</span>
            </div>
            <div className="arch-link"><span>PERSISTE</span><i>→</i></div>
            <div className="arch-node arch-local">
              <small>FUENTE DE VERDAD</small>
              <strong>Drift + SQLCipher</strong>
              <span>Datos cifrados en reposo</span>
            </div>
            <div className="arch-link arch-link-network"><span>HTTPS · PUSH / PULL</span><i>⇄</i></div>
            <div className="arch-node arch-api">
              <small>AUTORIDAD DE SYNC</small>
              <strong>Node.js + Express</strong>
              <span>JWT · LWW · Idempotencia</span>
            </div>
            <div className="arch-link"><span>CONSULTA</span><i>→</i></div>
            <div className="arch-node arch-server">
              <small>PERSISTENCIA REMOTA</small>
              <strong>PostgreSQL</strong>
              <span>Estado consolidado + adjuntos</span>
            </div>
          </div>

          <div className="architecture-notes">
            <div><span>01</span><p><strong>Respuesta inmediata</strong>La UI nunca espera una petición HTTP para guardar.</p></div>
            <div><span>02</span><p><strong>Convergencia</strong>WorkManager sincroniza al recuperar conectividad.</p></div>
            <div><span>03</span><p><strong>Conflictos visibles</strong>Las decisiones LWW quedan en el historial.</p></div>
          </div>

          <div className="layer-explainer">
            <div className="layer-heading">
              <p className="section-kicker light">Dentro del cliente</p>
              <h3>La red nunca alimenta directamente la interfaz.</h3>
              <p>Cada capa tiene una sola responsabilidad. Así es posible probar la lógica sin emulador y sustituir infraestructura sin reescribir la UI.</p>
            </div>
            <ol className="layer-list">
              <li><span>01</span><div><strong>Widgets</strong><p>Renderizan el estado y convierten gestos en intenciones.</p></div></li>
              <li><span>02</span><div><strong>Notifier · Riverpod</strong><p>Coordina el estado de presentación e inyecta dependencias.</p></div></li>
              <li><span>03</span><div><strong>Repository</strong><p>Define las operaciones del dominio y oculta de dónde vienen los datos.</p></div></li>
              <li><span>04</span><div><strong>Drift · SQLite</strong><p>Es la fuente única de verdad; sus streams actualizan la pantalla.</p></div></li>
              <li><span>05</span><div><strong>SyncTask</strong><p>Lee la cola pendiente y usa Dio solo cuando existe conectividad.</p></div></li>
            </ol>
          </div>
        </div>
      </section>

      <section className="sync-flow shell section-pad" id="sincronizacion">
        <div className="section-heading split-heading">
          <div><p className="section-kicker">Ciclo de sincronización</p><h2>Una ruta predecible para cada cambio.</h2></div>
          <p>Los estados son explícitos. Si algo falla, la nota permanece local y el usuario conserva el control.</p>
        </div>
        <div className="flow-steps">
          <article><span>01 · &lt;100 ms</span><h3>Escribe local</h3><p>Drift guarda el contenido, genera un UUID y marca la operación como <code>PENDING</code>.</p></article>
          <article><span>02 · POST /sync/push</span><h3>Envía un lote</h3><p>WorkManager agrupa pendientes. La clave <code>(uuid, version)</code> permite reintentar sin duplicar.</p></article>
          <article><span>03 · LWW</span><h3>Resuelve</h3><p>El servidor compara versiones y <code>updated_at</code>; responde por cada operación.</p></article>
          <article><span>04 · GET /sync/pull</span><h3>Converge</h3><p>El cliente descarga cambios posteriores al último timestamp y actualiza su base local.</p></article>
        </div>

        <div className="state-section">
          <div className="state-intro">
            <p className="section-kicker">Máquina de estados</p>
            <h3>Cada registro explica qué está ocurriendo.</h3>
            <p>La sincronización no es un indicador global ambiguo: cada nota conserva su propio estado y puede recuperarse de manera independiente.</p>
          </div>
          <div className="state-grid">
            {syncStates.map((item) => (
              <article key={item.state}>
                <code>{item.state}</code>
                <h4>{item.title}</h4>
                <p>{item.text}</p>
              </article>
            ))}
          </div>
        </div>

        <div className="edge-cases">
          <article>
            <span>CONFLICTOS</span>
            <h3>Last-Write-Wins, pero con memoria.</h3>
            <p>Gana la escritura con el <code>updated_at</code> más reciente. La versión descartada no desaparece silenciosamente: se registra en <code>HISTORIAL_CAMBIO</code> para auditoría.</p>
          </article>
          <article>
            <span>ELIMINACIONES</span>
            <h3>Un borrado también debe viajar.</h3>
            <p>Notium crea un tombstone con <code>is_deleted = true</code>. Solo se purga cuando el servidor confirma su propagación, evitando que otro dispositivo “resucite” la nota.</p>
          </article>
        </div>
      </section>

      <section className="technology" id="tecnologia">
        <div className="shell section-pad">
          <div className="tech-grid">
            <div className="tech-copy">
              <p className="section-kicker">Tecnología</p>
              <h2>Cada tecnología resuelve un riesgo concreto.</h2>
              <p>
                El stack no se eligió por popularidad. Cada pieza responde a una
                restricción: trabajar sin red, proteger datos locales, reintentar sin
                duplicar y ser mantenible por un solo desarrollador.
              </p>
              <a href={`${githubUrl}/blob/main/doc/doc.md`} target="_blank" rel="noreferrer">Leer decisiones de arquitectura ↗</a>
            </div>
            <div className="decision-list" aria-label="Decisiones del stack tecnológico">
              {stackDecisions.map((item, index) => (
                <article key={item.technology}>
                  <div className="decision-index">{String(index + 1).padStart(2, "0")}</div>
                  <div>
                    <span>{item.layer}</span>
                    <h3>{item.technology}</h3>
                    <p>{item.reason}</p>
                    <small>{item.tradeoff}</small>
                  </div>
                </article>
              ))}
            </div>
          </div>
          <div className="quality-strip">
            <div><strong>83</strong><span>pruebas Flutter</span></div>
            <div><strong>44</strong><span>pruebas backend</span></div>
            <div><strong>4</strong><span>migraciones locales</span></div>
            <a href={apiHealthUrl} target="_blank" rel="noreferrer"><i /> API pública <span>comprobar ↗</span></a>
          </div>
        </div>
      </section>

      <section className="security shell section-pad" id="seguridad">
        <div className="section-heading split-heading">
          <div><p className="section-kicker">Seguridad y operación</p><h2>Protección en cada frontera.</h2></div>
          <p>Offline-first coloca más datos en el dispositivo. Por eso la seguridad no puede depender únicamente del servidor.</p>
        </div>
        <div className="security-grid">
          <article><span>EN REPOSO</span><h3>SQLCipher</h3><p>La base SQLite completa permanece cifrada. La pérdida física del teléfono no expone directamente las notas.</p></article>
          <article><span>IDENTIDAD</span><h3>Keystore + JWT</h3><p>Access y refresh tokens viven en almacenamiento seguro; la expiración puede validarse localmente durante una desconexión.</p></article>
          <article><span>EN TRÁNSITO</span><h3>HTTPS / TLS</h3><p>Push, pull, autenticación y adjuntos viajan cifrados. La API valida que cada entidad pertenezca al usuario autenticado.</p></article>
          <article><span>OPERACIÓN</span><h3>Docker + healthcheck</h3><p>Frontend, API y PostgreSQL se despliegan de forma reproducible; el estado de la API puede comprobarse públicamente.</p></article>
        </div>
        <div className="architecture-summary">
          <span>La idea central</span>
          <p><strong>La base local da disponibilidad.</strong> El historial da trazabilidad. La idempotencia permite reintentar. El servidor hace converger dispositivos.</p>
        </div>
      </section>

      <section className="final-cta shell section-pad">
        <div className="cta-panel">
          <p className="section-kicker light">Código abierto</p>
          <h2>Construido para funcionar cuando internet no lo hace.</h2>
          <p>Explora el código, las pruebas, el contrato OpenAPI y las decisiones detrás de Notium.</p>
          <div className="hero-actions">
            <a className="button button-light" href={onlineDemoUrl} target="_blank" rel="noreferrer">Probar en el navegador ↗</a>
            <a className="button button-outline-light" href={apkDownloadUrl}>Descargar para Android ↓</a>
          </div>
          <div className="cta-grid" aria-hidden="true" />
        </div>
      </section>

      <footer className="footer shell">
        <a className="brand" href="#inicio"><span className="brand-mark">N</span><span>NOTIUM</span></a>
        <p>Diseñado y desarrollado por Jhonatan Castro.</p>
        <p>ADSO · SENA · 2026</p>
      </footer>
    </main>
  );
}
