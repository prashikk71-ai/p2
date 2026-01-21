package main

import (
    "fmt"
    "html/template"
    "net/http"
    "strconv"
)

type CalcData struct {
    Num1    float64
    Num2    float64
    Op      string
    Result  string
    Error   string
}

func main() {
    http.HandleFunc("/", indexHandler)
    http.HandleFunc("/calculate", calculateHandler)
    http.ListenAndServe(":8080", nil)
}

func indexHandler(w http.ResponseWriter, r *http.Request) {
    tmpl := `
    <!DOCTYPE html>
    <html>
    <head>
        <title>Simple Web Calculator</title>
        <style>
            body { font-family: Arial, sans-serif; text-align: center; margin-top: 50px; }
            input, select, button { margin: 10px; padding: 10px; }
        </style>
    </head>
    <body>
        <h1>Simple Calculator</h1>
        <form action="/calculate" method="post">
            <input type="number" name="num1" step="any" required>
            <select name="op">
                <option value="+">+</option>
                <option value="-">-</option>
                <option value="*">*</option>
                <option value="/">/</option>
            </select>
            <input type="number" name="num2" step="any" required>
            <button type="submit">Calculate</button>
        </form>
        {{if .Result}}<p>Result: {{.Result}}</p>{{end}}
        {{if .Error}}<p style="color:red;">Error: {{.Error}}</p>{{end}}
    </body>
    </html>
    `
    t := template.Must(template.New("calc").Parse(tmpl))
    t.Execute(w, CalcData{})
}

func calculateHandler(w http.ResponseWriter, r *http.Request) {
    if r.Method != "POST" {
        http.Redirect(w, r, "/", http.StatusSeeOther)
        return
    }

    num1Str := r.FormValue("num1")
    num2Str := r.FormValue("num2")
    op := r.FormValue("op")

    num1, err1 := strconv.ParseFloat(num1Str, 64)
    num2, err2 := strconv.ParseFloat(num2Str, 64)

    data := CalcData{Num1: num1, Num2: num2, Op: op}

    if err1 != nil || err2 != nil {
        data.Error = "Invalid numbers"
        renderTemplate(w, data)
        return
    }

    var result float64
    switch op {
    case "+":
        result = num1 + num2
    case "-":
        result = num1 - num2
    case "*":
        result = num1 * num2
    case "/":
        if num2 == 0 {
            data.Error = "Division by zero"
            renderTemplate(w, data)
            return
        }
        result = num1 / num2
    default:
        data.Error = "Invalid operation"
        renderTemplate(w, data)
        return
    }

    data.Result = fmt.Sprintf("%.2f", result)
    renderTemplate(w, data)
}

func renderTemplate(w http.ResponseWriter, data CalcData) {
    tmpl := `
    <!DOCTYPE html>
    <html>
    <head>
        <title>Simple Web Calculator</title>
        <style>
            body { font-family: Arial, sans-serif; text-align: center; margin-top: 50px; }
            input, select, button { margin: 10px; padding: 10px; }
        </style>
    </head>
    <body>
        <h1>Simple Calculator</h1>
        <form action="/calculate" method="post">
            <input type="number" name="num1" value="{{.Num1}}" step="any" required>
            <select name="op">
                <option value="+" {{if eq .Op "+"}}selected{{end}}>+</option>
                <option value="-" {{if eq .Op "-"}}selected{{end}}>-</option>
                <option value="*" {{if eq .Op "*"}}selected{{end}}>*</option>
                <option value="/" {{if eq .Op "/"}}selected{{end}}>/</option>
            </select>
            <input type="number" name="num2" value="{{.Num2}}" step="any" required>
            <button type="submit">Calculate</button>
        </form>
        {{if .Result}}<p>Result: {{.Result}}</p>{{end}}
        {{if .Error}}<p style="color:red;">Error: {{.Error}}</p>{{end}}
    </body>
    </html>
    `
    t := template.Must(template.New("calc").Parse(tmpl))
    t.Execute(w, data)
}
