# Guía de Despliegue en Vercel - Modus Pampa v3

## 🚀 Despliegue Automático

### Opción 1: Desde GitHub (Recomendado)

1. **Subir código a GitHub:**
   ```bash
   git add .
   git commit -m "feat: prepare for Vercel deployment"
   git push origin main
   ```

2. **Conectar con Vercel:**
   - Ve a [vercel.com](https://vercel.com)
   - Inicia sesión con tu cuenta GitHub
   - Clic en "New Project"
   - Selecciona tu repositorio `modus_pampa_v3`
   - Vercel detectará automáticamente la configuración

3. **Configuración automática:**
   - Vercel usará `vercel.json` para la configuración
   - Build Command: `chmod +x install.sh && ./install.sh && flutter build web --release`
   - Output Directory: `build/web`

### Opción 2: Despliegue Manual con Vercel CLI

1. **Instalar Vercel CLI:**
   ```bash
   npm install -g vercel
   ```

2. **Login en Vercel:**
   ```bash
   vercel login
   ```

3. **Desplegar:**
   ```bash
   vercel --prod
   ```

## 📁 Archivos de Configuración

### `vercel.json`
```json
{
  "version": 2,
  "name": "modus-pampa-v3",
  "buildCommand": "chmod +x install.sh && ./install.sh && flutter build web --release",
  "outputDirectory": "build/web",
  "installCommand": "echo 'Using custom install script'",
  "framework": null,
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ]
}
```

### `package.json`
Define scripts y metadata para Vercel.

### `install.sh`
Script personalizado que:
- Instala Flutter en el entorno de Vercel
- Configura dependencias web
- Prepara el entorno de build

## 🔧 Variables de Entorno (Opcional)

Si necesitas configurar variables de entorno en Vercel:

1. **En el Dashboard de Vercel:**
   - Ve a tu proyecto
   - Settings → Environment Variables
   - Agrega las variables necesarias:
     - `BACKEND_URL`: URL del backend
     - `CLOUDINARY_CLOUD_NAME`: Para imágenes
     - `CLOUDINARY_API_KEY`: Para imágenes

2. **En el código Flutter:**
   ```dart
   // Las variables se pueden leer en tiempo de build
   const String.fromEnvironment('BACKEND_URL', 
     defaultValue: 'https://modus-pampa-backend-oficial.onrender.com')
   ```

## 🌐 Configuración de Dominio

### Dominio Personalizado
1. **En Vercel Dashboard:**
   - Ve a Settings → Domains
   - Agrega tu dominio personalizado
   - Configura DNS según las instrucciones

### SSL Automático
- Vercel proporciona SSL automático
- Se renueva automáticamente

## 📊 Optimizaciones de Rendimiento

### Tree Shaking Automático
El build ya incluye optimizaciones:
- Reducción de fuentes (99%+ de reducción)
- Eliminación de código no utilizado
- Compresión automática

### Cache Headers
Vercel configura automáticamente:
- Cache de assets estáticos
- Compresión gzip/brotli
- CDN global

## 🔍 Monitoreo y Analytics

### Vercel Analytics
1. **Habilitar en Dashboard:**
   - Ve a tu proyecto
   - Analytics tab
   - Enable Analytics

2. **Métricas disponibles:**
   - Page views
   - Unique visitors
   - Performance metrics
   - Core Web Vitals

### Error Tracking
- Logs automáticos en Vercel Dashboard
- Función de debug disponible

## 🚨 Troubleshooting

### Problemas Comunes

#### 1. Build Fails
```bash
# Error: Flutter not found
# Solución: Verificar que install.sh tenga permisos de ejecución
chmod +x install.sh
```

#### 2. Assets No Cargan
```bash
# Error: 404 en assets
# Solución: Verificar base href en index.html
# Asegurar que rewrites esté configurado correctamente
```

#### 3. Routing No Funciona
```bash
# Error: 404 en rutas de Flutter
# Solución: Verificar rewrites en vercel.json
# Todas las rutas deben redirigir a index.html
```

#### 4. Performance Issues
```bash
# Optimizaciones adicionales:
flutter build web --release --tree-shake-icons
# Usar --split-debug-info para bundles más pequeños
```

### Logs de Debug
```bash
# Ver logs de build en tiempo real
vercel --logs

# Ver logs de la función
vercel logs <deployment-url>
```

## 📱 Testing del Despliegue

### Checklist Pre-Deploy
- [ ] Build local exitoso: `flutter build web`
- [ ] Test en localhost: `flutter run -d chrome`
- [ ] Verificar rutas funcionan
- [ ] Test de conectividad online/offline
- [ ] Verificar carga de imágenes
- [ ] Test de responsividad

### Checklist Post-Deploy
- [ ] URL principal carga correctamente
- [ ] Login funciona con credenciales
- [ ] Navegación entre páginas
- [ ] Funcionalidad offline
- [ ] Rendimiento aceptable (< 3s carga inicial)
- [ ] Compatible con móvil

## 🔄 CI/CD Automático

### GitHub Actions (Opcional)
Para deploy automático en cada push:

```yaml
# .github/workflows/deploy.yml
name: Deploy to Vercel
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: amondnet/vercel-action@v20
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.ORG_ID }}
          vercel-project-id: ${{ secrets.PROJECT_ID }}
```

## 📞 Soporte

### Recursos Útiles
- [Vercel Documentation](https://vercel.com/docs)
- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)
- [Vercel Community](https://github.com/vercel/vercel/discussions)

### Contacto
Para problemas específicos del proyecto:
- Revisar logs en Vercel Dashboard
- Verificar configuración en `vercel.json`
- Consultar documentación de Flutter Web

---

**Versión**: 1.0.0+1  
**Última actualización**: Agosto 2025  
**Plataforma objetivo**: Web (Vercel)