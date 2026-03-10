using FluentValidation;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using System.Diagnostics;

namespace AnimeHub.Api.Validation;

public sealed class FluentValidationActionFilter : IAsyncActionFilter
{
    public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
    {
        // valida só argumentos que têm validator registrado
        var validators = context.HttpContext.RequestServices.GetServices<IValidator>();

        // pega validators “tipados” para os argumentos do action
        var failures = new Dictionary<string, string[]>(StringComparer.OrdinalIgnoreCase);

        foreach (var arg in context.ActionArguments.Values)
        {
            if (arg is null) continue;

            // resolve IValidator<T> para o tipo do arg
            var validatorType = typeof(IValidator<>).MakeGenericType(arg.GetType());
            var validator = context.HttpContext.RequestServices.GetService(validatorType);
            if (validator is null) continue;

            var validateMethod = validatorType.GetMethod("ValidateAsync", new[] { arg.GetType(), typeof(CancellationToken) });
            if (validateMethod is null) continue;

            var task = (Task)validateMethod.Invoke(validator, new object[] { arg, context.HttpContext.RequestAborted })!;
            await task.ConfigureAwait(false);

            var resultProp = task.GetType().GetProperty("Result");
            var result = (FluentValidation.Results.ValidationResult?)resultProp?.GetValue(task);

            if (result?.IsValid != false) continue;

            foreach (var f in result.Errors)
            {
                if (string.IsNullOrWhiteSpace(f.PropertyName)) continue;

                if (!failures.TryGetValue(f.PropertyName, out var arr))
                {
                    failures[f.PropertyName] = new[] { f.ErrorMessage };
                }
                else
                {
                    failures[f.PropertyName] = arr.Concat(new[] { f.ErrorMessage }).ToArray();
                }
            }
        }

        if (failures.Count == 0)
        {
            await next();
            return;
        }

        var problem = new ValidationProblemDetails(failures)
        {
            Status = StatusCodes.Status400BadRequest,
            Title = "Validation failed",
            Type = "https://httpstatuses.com/400",
            Instance = context.HttpContext.Request.Path
        };

        problem.Extensions["traceId"] =
            Activity.Current?.TraceId.ToString() ?? context.HttpContext.TraceIdentifier;

        context.Result = new BadRequestObjectResult(problem)
        {
            ContentTypes = { "application/problem+json" }
        };
    }
}