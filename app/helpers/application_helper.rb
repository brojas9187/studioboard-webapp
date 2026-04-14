module ApplicationHelper
  def flash_classes(type)
    case type.to_sym
    when :notice
      "border-emerald-200 bg-emerald-50 text-emerald-900"
    when :alert
      "border-rose-200 bg-rose-50 text-rose-900"
    else
      "border-slate-200 bg-white text-slate-900"
    end
  end

  def plan_badge_classes(plan)
    plan == "pro" ? "bg-amber-100 text-amber-900" : "bg-slate-100 text-slate-700"
  end

  def role_badge_classes(role)
    case role
    when "owner"
      "bg-indigo-100 text-indigo-900"
    when "admin"
      "bg-sky-100 text-sky-900"
    else
      "bg-slate-100 text-slate-700"
    end
  end

  def nav_link_to(name, path, **options)
    classes = class_names(
      "nav-link",
      { "nav-link-active" => current_page?(path) },
      options.delete(:class)
    )

    link_to name, path, **options.merge(class: classes)
  end

  def task_status_badge_classes(task)
    task.completed? ? "bg-emerald-100 text-emerald-900" : "bg-amber-100 text-amber-900"
  end

  def translated_plan_name(plan)
    t("app.plan_names.#{plan}")
  end

  def translated_role_name(role)
    t("app.role_names.#{role}")
  end

  def locale_name(locale)
    t("app.locales.#{locale}")
  end

  def locale_switch_button_classes(locale)
    class_names(
      "rounded-full px-3 py-2 text-xs font-semibold uppercase tracking-[0.18em] transition",
      current_locale.to_s == locale.to_s ? "bg-slate-900 text-white" : "text-slate-600 hover:bg-slate-100 hover:text-slate-900"
    )
  end

  def member_role_options
    %w[admin member].map { |role| [translated_role_name(role), role] }
  end

  def membership_option_label(membership)
    "#{membership.user.display_name} (#{translated_role_name(membership.role)})"
  end

  def payment_method_label(payment_method_type)
    t("app.payment_method_types.#{payment_method_type}", default: payment_method_type.to_s.humanize)
  end
end
