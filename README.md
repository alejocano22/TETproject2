# Proyecto 2 - Tópicos especiales en telemática
## Estudiantes y roles
Alejandro Cano Munera 
> email: acanom@eafit.edu.co <br/>
> Rol: Líder <br/>
> QA: Rendimiento <br/>

Luis Javier Palacio Mesa 
> email: ljpalaciom@eafit.edu.co <br/>
> Rol: Programador <br/>
> QA: Disponibilidad <br/>

Sebastián Giraldo Gómez 
> email: sgiraldog@eafit.edu.co <br/>
> Rol: Analista <br/>
> QA: Seguridad <br/>

## Requisitos 
# Disponibilidad: 
| Atributo | Descripción |
| ------ | ------ |
| Escalamiento horizontal | El sistema deberá ser capaz de escalar horizontalmente cuando el sistema tengo en promedio un uso del 60 % de la CPU |
| Balanceo de cargas | El sistema deberá será capaz de redirigir el tráfico de peticiones de los usuarios de una manera equilibrada entre diferentes instancias de Moodle. |
| Disponibilidad en la capa de datos | Los datos deben ser almacenados en una capa diferente a la de servicio. |

# Rendimiento: 
| Atributo | Descripción |
| ------ | ------ |
| Tiempo de respuesta | La aplicación debe de tener tiempos de respuesta menores a 1 segundo |
| Concurrencia | La aplicación debe soportar una concurrencia del 10%, es decir, 2.000 usuarios en un periodo de 60 segundos |
| Cacheo | El sistema debe implementar un sistema de cacheo CDN  |
| Sistema de monitoreo | El sistema debe tener un sistema de monitoreo donde como mínimo se puedan observar el tráfico de peticiones, el tráfico de usuarios, el gasto estimado y procesamiento usado. |

# Seguridad: 
| Atributo | Descripción |
| ------ | ------ |
| Certificado | El sistema debe contar con un certificado válido que permita comunicaciones seguras y encriptadas. |
| SSO | El sistema debe implementar un proceso de autenticación tipo SSO para permitir a los usuarios autenticarse con redes sociales. |
| Two Factor | El sistema deberá contar con un campo adicional el cual debe ser un token único con expiración determinada para aumentar la seguridad en la autenticación. |
| Protección ante ataques | El sistema debe estar protegido contra ataques DDoS, XSS y CSRF |
| Protección ante SQL Injection | El sistema debe implementar estrategias y herramientas para eliminar consultas SQL en formularios. |

## Diseño para la escalabilidad
# Patrones de arquitectura
![Diseño de arquitectura](https://github.com/alejocano22/TETproject2/blob/master/Diagramas/Diagrama%20de%20dise%C3%B1o.jpeg)


En este diagrama podemos ver que CloudFlare está como intermediario al proveernos diferentes servicios que nos ayuda con los requisitos no funcionales como seguridad, rendimiento, disponibilidad. Posteriormente se encuentra el balanceador de cargas el cual distribuye el tráfico de peticiones entre las instancias disponibles. Así mismo también tenemos un grupo de escalamiento el cuál permite crear nuevas instancias de Moodle en caso de ser necesario. Por otro lado cada instancia cuenta con una conexión a la base de datos, y la configuración de la aplicación Moodle se sincroniza usando el sistema de almacenamiento S3.
Cabe recalcar que entre los dispositivos y CloudFlare la conexión es encriptada
Y de cloudflare al balanceador de carga también está encriptado
# Herramientas a utilizar
AutoScaling group, EC2, Load Balancer, CloudFlare, RDS, S3

## DNS
La petición del dominio se realizó mediante dot.tk (Freenom), después se realizó el proceso de creación de cuenta y se seleccionó un plan, en este caso uno gratis. Una vez ya poseíamos el dominio, era necesario agregar dos nameservers para poder verificar, configurar y ceder el poder a cloudfare y esto dio como resultado que se activaran diversas opciones en CloudFlare, para la óptima configuración de todos los QA necesarios, adicional a esto se agregaron los CNAMES para funcionar con www y el dominio base.

##	Certificados de seguridad
Para poder crear el balanceador de carga con protocolo https, debimos pedir un certificado TLS para poder lograr comunicaciones encriptadas y para ello usamos CloudFlare quien los provee de manera gratuita. Así que en CloudFlare, usamos la cuenta a la que ya le habíamos configurado el DNS, fuimos a la sección de SSL/TLS, luego a certificados de origen y seleccionamos la opción de crear certificado. Seleccionamos el algoritmo de cifrado por defecto (RSA) y seleccionamos 1 año para la validez del certificado.
Una vez teníamos el certificado, fuimos a AWS, seleccionamos la opción de subir un certificado a IAM y finalmente llenamos los campos correspondientes del certificado.

##	Automatización DevOps
La arquitectura planteada para lograr por ejemplo la fácil instalación de plugins o temas se basa en buscar una forma para compartir los archivos de configuración entre las instancias de Moodle. Para lograr esto, debimos guardar los archivos en un lugar en común y aunque consideramos que no es lo indicado, tuvimos que usar el servicio S3 de AWS en vez de EFS porque no estaba disponible en la cuenta Educate. 
También se consideró e intentó el uso de Gitlab para usar los pipelines que ofrece, pero debido a que se decidió sincronizar con S3 toda la carpeta de Moodle, y puesto que todas las instancias pueden hacer cambios en el S3, versionar esa carpeta con Gitlab se vuelve muy complejo debido a los conflictos de merge.

##	Servicios utilizados en nube
Los servicios utilizados en nube fueron:
- AWS Educate
- CloudFlare Free

##	Análisis de Costo de la solución
| Servicio | Descripción | Precio | Concepto | Necesario | Cantidad | Total | 
| ------ | ------ | ------ | ------ | ------ | ------ | ------ |
| EC2 | t2.micro | $ 0.0183 | Hora | 720 | 3 | $ 40.18 |
| S3 | Estándar | $ 0.0405 | Gb/Mes | 500 | 1 | $ 20.25 | 
| RDS | db.t2.micro | $ 0.0170 | Hora | 720 | 1 | $ 12.24 | 
| Load Balancer | Classic | $ 0.0340 | Hora | 720 | 1 | $ 24.48 | 
| CloudWatch | Monitoreo | $ 0.03000 | Métrica | 7 | 3 | $ 6.30 |

| Total mensual | Total anual |
| ------ | ------ | 
| $ 103.45 | $ 1241.35 |

> Precio basado en servicios por demanda.
> Precio en USD.
> Meses de 30 días.

##	Documentación de monitoreo y gestión
Para implementar un sistema de monitoreo de operación que nos brindara estadísticas e información pertinente para tomar acciones de mejoramiento en la aplicación utilizamos dos plataformas: CloudFlare y AWS CloudWatch. 

##	Documentación de recuperación ante desastres
En la parte de backups y recuperación se activó la opción de backups automáticos en la base de datos, control de versiones en el s3 y copiar una carpeta de un bucket a otro en s3

## Documentación adicional
> Nota: Para obtener información adicional por favor visitar el documento base
> Documento: https://github.com/alejocano22/TETproject2/tree/master/documentos
