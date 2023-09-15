# Portal properties

```
## DSM
feature.flag.LPS-164563=true

## enable adding system object definitions
feature.flag.LPS-167253=true

## enable object translations
feature.flag.LPS-146755=true
feature.flag.LPS-172017=true

## enable sort
feature.flag.LPS-188645=true

feature.flag.LPS-135430=true
feature.flag.LPS-183727=true
```

# Adapt the gradle build to your local environment

```
build.doFirst {
    println("Building Ballerina")
    if (System.getProperty('os.name').toLowerCase(Locale.ROOT).contains('windows')) {
        exec { 
        	commandLine 'C:\\Program Files\\Ballerina\\bin\\bal.bat', 'build'
        }
    } else {
        exec { 
        	commandLine 'bal', 'build'
        }
    }
}
```
